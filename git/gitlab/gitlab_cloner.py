#!/usr/bin/env python3
"""
GitLab Repository Cloner

This script clones all group repositories from a GitLab instance.
Note: This file was renamed from 'gitlab.py' to 'gitlab_cloner.py' to avoid
naming conflicts with the python-gitlab package import.
"""

import concurrent.futures
import configparser
import logging
import os
import subprocess
import sys
from dataclasses import dataclass
from getpass import getpass
from pathlib import Path
from threading import Lock
from typing import List, Optional

import gitlab  # type: ignore[import-untyped]
import gitlab.exceptions as gitlab_exceptions  # type: ignore[import-untyped]
from tqdm import tqdm  # type: ignore[import-untyped]

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("gitlab_clone.log"), logging.StreamHandler()],
)

logger = logging.getLogger(__name__)

# Thread-safe print lock
print_lock = Lock()


@dataclass
class Config:
    """Configuration class for GitLab cloning script."""

    gitlab_url: str
    gitlab_token: str
    clone_directory: str
    namespace: str
    max_workers: int = 4
    per_page: int = 20

    @classmethod
    def from_file(cls, config_path="config.ini"):
        """Load configuration from file."""
        config = configparser.ConfigParser()
        if os.path.exists(config_path):
            config.read(config_path)

        return cls(
            gitlab_url=config.get("gitlab", "url", fallback="gitlab.com"),
            gitlab_token=cls._get_token(config),
            clone_directory=config.get("paths", "clone_dir", fallback="./repos"),
            namespace=config.get("gitlab", "namespace", fallback=""),
            max_workers=config.getint("performance", "max_workers", fallback=4),
            per_page=config.getint("performance", "per_page", fallback=20),
        )

    @staticmethod
    def _get_token(config):
        """Get GitLab token from environment or config file."""
        token = os.getenv("GITLAB_TOKEN")
        if not token:
            token = config.get("gitlab", "token", fallback=None)
        if not token:
            token = getpass("Enter GitLab token: ")
        return token

    @property
    def gitlab_url_http(self):
        """Get full HTTP URL for GitLab."""
        if not self.gitlab_url.startswith(("http://", "https://")):
            return f"https://{self.gitlab_url}"
        return self.gitlab_url


class GitLabCloner:
    """GitLab repository cloner with improved error handling and performance."""

    def __init__(self, config: Config):
        self.config = config
        self.gl: Optional["gitlab.Gitlab"] = None  # type: ignore[name-defined]

    def authenticate(self):
        """Authenticate with GitLab API."""
        try:
            self.gl = gitlab.Gitlab(  # type: ignore[attr-defined]
                self.config.gitlab_url_http, private_token=self.config.gitlab_token
            )
            if self.gl is not None:
                self.gl.auth()
            logger.info("Successfully authenticated with GitLab")
        except gitlab_exceptions.GitlabAuthenticationError:
            logger.error("Authentication failed. Check your token.")
            sys.exit(1)
        except gitlab_exceptions.GitlabError as e:
            logger.error("GitLab API error: %s", e)
            sys.exit(1)
        except Exception as e:  # pylint: disable=broad-exception-caught
            # Reason: Authentication can fail in various unexpected ways (network, SSL, etc.)
            logger.error("Unexpected error during authentication: %s", e)
            sys.exit(1)

    def detect_namespace_type(self, namespace: str) -> str:
        """Detect if namespace is a user or group."""
        if not namespace:
            raise ValueError("Namespace cannot be empty")

        if self.gl is None:
            raise ValueError("GitLab client not authenticated")

        try:
            # Try to get as a group first
            try:
                group = self.gl.groups.get(namespace)
                logger.info("Detected '%s' as a group: %s", namespace, group.name)
                return "group"
            except gitlab_exceptions.GitlabGetError:
                pass

            # Try to get as a user
            try:
                user = self.gl.users.list(username=namespace)
                if user:
                    logger.info("Detected '%s' as a user: %s", namespace, user[0].name)
                    return "user"
            except gitlab_exceptions.GitlabGetError:
                pass

            # If neither worked, raise an error
            raise ValueError(f"Namespace '{namespace}' not found or not accessible")

        except gitlab_exceptions.GitlabError as e:
            logger.error("Error detecting namespace type: %s", e)
            raise

    def get_user_projects(self, username: str) -> List:
        """Get all projects owned by the authenticated user using the owned=True approach.

        This method uses the owned=True filter instead of the problematic user_id parameter
        to avoid infinite loop pagination issues with the GitLab API.

        Note: This requires the authentication token to belong to the target user.
        """
        if self.gl is None:
            raise ValueError("GitLab client not authenticated")

        projects = []
        page = 1

        logger.info("Fetching owned projects for user: %s", username)
        logger.info("Using owned=True approach to avoid GitLab API pagination issues")

        while True:
            try:
                # Use owned=True instead of user_id parameter to avoid infinite loop
                # This approach gets all projects owned by the authenticated user
                page_projects = self.gl.projects.list(
                    owned=True, page=page, per_page=self.config.per_page, all=False
                )

                # Check if we got no projects or fewer than expected (end of pagination)
                if not page_projects or len(page_projects) < self.config.per_page:
                    if page_projects:
                        # Add the final partial page
                        projects.extend(page_projects)
                        logger.info(
                            "Fetched page %s, found %s owned projects (final page)",
                            page,
                            len(page_projects),
                        )
                    break

                projects.extend(page_projects)
                logger.info("Fetched page %s, found %s owned projects", page, len(page_projects))
                page += 1

                # Reduced safety limit for user projects (from 1000 to 50)
                if page > 50:
                    logger.warning(
                        "Reached maximum page limit (50) for user %s, stopping pagination", username
                    )
                    break

            except gitlab_exceptions.GitlabError as e:
                logger.error("Error fetching owned projects page %s: %s", page, e)
                break

        logger.info("Total owned projects found: %s", len(projects))
        return projects

    def get_group_projects_by_namespace(self, group_path: str) -> List:
        """Get all projects for a specific group."""
        if self.gl is None:
            raise ValueError("GitLab client not authenticated")

        projects = []
        page = 1

        logger.info("Fetching projects for group: %s", group_path)

        try:
            group = self.gl.groups.get(group_path)
        except gitlab_exceptions.GitlabGetError as e:
            logger.error("Group '%s' not found: %s", group_path, e)
            return []

        while True:
            try:
                page_projects = group.projects.list(
                    page=page,
                    per_page=self.config.per_page,
                    all=False,
                    include_subgroups=True,
                )

                # Check if we got no projects or fewer than expected (end of pagination)
                if not page_projects or len(page_projects) < self.config.per_page:
                    if page_projects:
                        # Add the final partial page
                        projects.extend(page_projects)
                        logger.info(
                            "Fetched page %s, found %s group projects (final page)",
                            page,
                            len(page_projects),
                        )
                    break

                projects.extend(page_projects)
                logger.info("Fetched page %s, found %s group projects", page, len(page_projects))
                page += 1

                # Safety check to prevent infinite loops
                if page > 1000:  # Reasonable upper limit
                    logger.warning(
                        "Reached maximum page limit (1000) for group %s, stopping pagination",
                        group_path,
                    )
                    break

            except gitlab_exceptions.GitlabError as e:
                logger.error("Error fetching group projects page %s: %s", page, e)
                break

        logger.info("Total group projects found: %s", len(projects))
        return projects

    def get_group_projects(self) -> List:
        """Get all group projects with pagination."""
        if self.gl is None:
            raise ValueError("GitLab client not authenticated")

        projects = []
        page = 1

        logger.info("Fetching projects from GitLab...")

        while True:
            try:
                page_projects = self.gl.projects.list(
                    page=page, per_page=self.config.per_page, all=False
                )

                if not page_projects:
                    break

                # Filter group projects
                group_projects = [p for p in page_projects if p.namespace["kind"] == "group"]
                projects.extend(group_projects)

                logger.info("Fetched page %s, found %s group projects", page, len(group_projects))
                page += 1

            except gitlab_exceptions.GitlabError as e:
                logger.error("Error fetching page %s: %s", page, e)
                break

        logger.info("Total group projects found: %s", len(projects))
        return projects

    def get_namespace_projects(self) -> List:
        """Get all projects for the configured namespace (auto-detect user vs group)."""
        if not self.config.namespace:
            logger.warning("No namespace specified, falling back to all group projects")
            return self.get_group_projects()

        try:
            namespace_type = self.detect_namespace_type(self.config.namespace)

            if namespace_type == "user":
                return self.get_user_projects(self.config.namespace)
            if namespace_type == "group":
                return self.get_group_projects_by_namespace(self.config.namespace)

            logger.error("Unknown namespace type: %s", namespace_type)
            return []

        except ValueError as e:
            logger.error("Namespace error: %s", e)
            return []
        except gitlab_exceptions.GitlabError as e:
            logger.error("GitLab API error getting namespace projects: %s", e)
            return []
        except Exception as e:  # pylint: disable=broad-exception-caught
            # Reason: Network errors, authentication issues, or other unexpected failures
            logger.error("Unexpected error getting namespace projects: %s", e)
            return []

    def get_default_branch(self, repo_path: Path) -> Optional[str]:
        """Get the default branch name for a repository."""
        try:
            # Try to get the default branch from remote
            result = subprocess.run(
                ["git", "symbolic-ref", "refs/remotes/origin/HEAD"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True,
                timeout=30,
            )
            return result.stdout.strip().split("/")[-1]
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            # Fallback to common branch names
            for branch in ["main", "master", "develop"]:
                try:
                    subprocess.run(
                        ["git", "checkout", branch],
                        cwd=repo_path,
                        check=True,
                        capture_output=True,
                        timeout=30,
                    )
                    return branch
                except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                    continue
            return None

    def get_relative_namespace_path(self, full_namespace_path: str) -> str:
        """
        Calculate the relative namespace path by removing the root namespace.

        Examples:
        - 'cynerio' -> '' (root level project)
        - 'cynerio/devops' -> 'devops'
        - 'cynerio/devops/infra' -> 'devops/infra'
        - 'cynerio/team/backend/api' -> 'team/backend/api'
        """
        if not self.config.namespace:
            # If no specific namespace configured, use the full path
            return full_namespace_path

        # Split the full path into components
        path_parts = full_namespace_path.split("/")

        # If the first part matches our root namespace, remove it
        if path_parts and path_parts[0] == self.config.namespace:
            # Remove the root namespace, keep the rest
            relative_parts = path_parts[1:]
            return "/".join(relative_parts) if relative_parts else ""

        # If it doesn't match our namespace, use the full path
        # This handles cases where we're cloning from a different namespace
        return full_namespace_path

    def safe_clone_project(self, project) -> bool:
        """Safely clone a project using subprocess."""
        full_namespace_path = project.namespace["full_path"]
        relative_namespace_path = self.get_relative_namespace_path(full_namespace_path)
        repo_url = project.ssh_url_to_repo

        # Use project.path instead of project.name to handle spaces and special characters
        # project.path is the URL-safe version that Git actually uses for directory names
        project_path = project.path
        project_display_name = project.name

        # Create target directory based on relative path
        if relative_namespace_path:
            target_dir = Path(self.config.clone_directory) / relative_namespace_path
        else:
            # Root level project - clone directly to base directory
            target_dir = Path(self.config.clone_directory)

        # Use project_path for actual filesystem operations
        project_dir = target_dir / project_path

        try:
            # Create directory safely
            target_dir.mkdir(parents=True, exist_ok=True)

            # Log the folder structure being created
            with print_lock:
                logger.debug(
                    "Folder structure: %s -> %s",
                    full_namespace_path,
                    relative_namespace_path or "(root)",
                )
                logger.debug("Target directory: %s", target_dir)
                logger.debug("Project directory: %s", project_dir)
                logger.debug("Display name: '%s' -> Path: '%s'", project_display_name, project_path)

            if project_dir.exists():
                # Repository exists, update it
                with print_lock:
                    logger.info("Updating existing repository: %s", project.name_with_namespace)

                # Get default branch and pull
                default_branch = self.get_default_branch(project_dir)
                if default_branch:
                    subprocess.run(
                        ["git", "checkout", default_branch],
                        cwd=project_dir,
                        check=True,
                        capture_output=True,
                        timeout=60,
                    )
                    subprocess.run(
                        ["git", "pull"],
                        cwd=project_dir,
                        check=True,
                        capture_output=True,
                        timeout=60,
                    )
                else:
                    # Check if this is an empty repository
                    try:
                        # Try to list branches - empty repos will have no branches
                        result = subprocess.run(
                            ["git", "branch", "-r"],
                            cwd=project_dir,
                            capture_output=True,
                            text=True,
                            timeout=30,
                            check=False,  # Don't raise exception for empty repos
                        )
                        if not result.stdout.strip():
                            # Empty repository - this is normal, not a failure
                            with print_lock:
                                logger.info(
                                    "Empty repository detected (no branches): %s",
                                    project.name_with_namespace,
                                )
                        else:
                            logger.warning(
                                "Could not determine default branch for %s", project_display_name
                            )
                            return False
                    except subprocess.CalledProcessError:
                        logger.warning(
                            "Could not determine default branch for %s", project_display_name
                        )
                        return False
            else:
                # Clone new repository
                with print_lock:
                    logger.info("Cloning new repository: %s", project.name_with_namespace)

                try:
                    subprocess.run(
                        ["git", "clone", repo_url],
                        cwd=target_dir,
                        check=True,
                        capture_output=True,
                        text=True,
                        timeout=300,
                    )

                    # Set up default branch
                    default_branch = self.get_default_branch(project_dir)
                    if not default_branch:
                        logger.warning(
                            "Could not set up default branch for %s", project_display_name
                        )

                except subprocess.CalledProcessError as e:
                    # Check if this is an empty repository
                    if (
                        "does not appear to be a git repository" in str(e.stderr)
                        or "remote: warning: You appear to have cloned an empty repository"
                        in str(e.stderr)
                        or "warning: You appear to have cloned an empty repository" in str(e.stderr)
                    ):

                        with print_lock:
                            logger.info(
                                "Empty repository detected for %s, creating empty folder",
                                project.name_with_namespace,
                            )

                        # Create empty directory for empty repository
                        project_dir.mkdir(parents=True, exist_ok=True)

                        # Initialize as git repository
                        subprocess.run(
                            ["git", "init"],
                            cwd=project_dir,
                            check=True,
                            capture_output=True,
                            text=True,
                            timeout=30,
                        )

                        # Add remote origin
                        subprocess.run(
                            ["git", "remote", "add", "origin", repo_url],
                            cwd=project_dir,
                            check=True,
                            capture_output=True,
                            text=True,
                            timeout=30,
                        )

                        # Empty repository handled successfully
                        with print_lock:
                            logger.info(
                                "✓ Empty repository setup completed for %s",
                                project.name_with_namespace,
                            )

                    else:
                        # Re-raise if it's not an empty repository issue
                        raise

            return True

        except subprocess.TimeoutExpired:
            logger.error("Timeout while processing %s", project_display_name)
            return False
        except subprocess.CalledProcessError as e:
            logger.error("Git operation failed for %s: %s", project_display_name, e)
            if e.stderr:
                logger.error("Git error output: %s", e.stderr)
            return False
        except (OSError, PermissionError) as e:
            logger.error("File system error processing %s: %s", project_display_name, e)
            return False
        except Exception as e:  # pylint: disable=broad-exception-caught
            # Reason: Git operations can fail in various unexpected ways
            logger.error("Unexpected error processing %s: %s", project_display_name, e)
            return False

    def clone_project_parallel(self, project) -> tuple:
        """Clone a single project (thread-safe)."""
        try:
            success = self.safe_clone_project(project)
            if success:
                with print_lock:
                    logger.info("✓ Successfully processed: %s", project.name_with_namespace)
                return project.name_with_namespace, True, None

            with print_lock:
                logger.warning("⚠ Partially processed: %s", project.name_with_namespace)
            return project.name_with_namespace, False, "Partial failure"
        except Exception as e:  # pylint: disable=broad-exception-caught
            # Reason: Parallel execution wrapper needs to catch all possible exceptions
            with print_lock:
                logger.error("✗ Failed: %s - %s", project.name_with_namespace, e)
            return project.name_with_namespace, False, str(e)

    def clone_all_projects(self):
        """Clone all projects from the configured namespace with parallel processing."""
        projects = self.get_namespace_projects()

        if not projects:
            logger.warning("No projects found for the specified namespace")
            return

        logger.info(
            "Starting to clone %s repositories with %s workers",
            len(projects),
            self.config.max_workers,
        )

        # Create base directory
        Path(self.config.clone_directory).mkdir(parents=True, exist_ok=True)

        # Track results
        successful = 0
        failed = 0
        failed_projects = []

        # Process projects in parallel with progress bar
        with tqdm(total=len(projects), desc="Processing repositories") as pbar:
            with concurrent.futures.ThreadPoolExecutor(
                max_workers=self.config.max_workers
            ) as executor:
                # Submit all tasks
                futures = {
                    executor.submit(self.clone_project_parallel, project): project
                    for project in projects
                }

                # Process completed tasks
                for future in concurrent.futures.as_completed(futures):
                    project_name_with_namespace, success, error = future.result()

                    if success:
                        successful += 1
                    else:
                        failed += 1
                        failed_projects.append((project_name_with_namespace, error))

                    pbar.update(1)

        # Print summary
        logger.info("\n%s", "=" * 50)
        logger.info("SUMMARY:")
        logger.info("Successfully processed: %s", successful)
        logger.info("Failed: %s", failed)
        logger.info("Total: %s", len(projects))

        if failed_projects:
            logger.info("\nFailed projects:")
            for name, error in failed_projects:
                logger.info("  - %s: %s", name, error)


def create_sample_config():
    """Create a sample configuration file."""
    config_content = """[gitlab]
# GitLab URL (without https://)
url = gitlab.com
# Token will be read from GITLAB_TOKEN environment variable
# token = your_token_here
# Namespace to clone from (user or group name)
# Examples: 'langburd' for user, 'cynerio' for organization/group
# Leave empty to clone all accessible group projects
namespace =

[paths]
# Directory where repositories will be cloned
clone_dir = ./repos

[performance]
# Number of parallel workers for cloning
max_workers = 4
# Number of projects to fetch per API call
per_page = 20
"""

    with open("config.ini.sample", "w", encoding="utf-8") as f:
        f.write(config_content)

    logger.info("Sample configuration file created: config.ini.sample")


def main():
    """Main function."""
    logger.info("Starting GitLab repository cloner")

    # Check if sample config should be created
    if len(sys.argv) > 1 and sys.argv[1] == "--create-config":
        create_sample_config()
        return

    try:
        # Load configuration
        config = Config.from_file()
        if config.namespace:
            namespace_info = ", Namespace: " + config.namespace
        else:
            namespace_info = ", Namespace: all groups"
        logger.info(
            "Configuration loaded - GitLab: %s, Clone dir: %s%s",
            config.gitlab_url,
            config.clone_directory,
            namespace_info,
        )

        # Initialize cloner
        cloner = GitLabCloner(config)

        # Authenticate and clone
        cloner.authenticate()
        cloner.clone_all_projects()

        logger.info("GitLab cloning process completed")

    except KeyboardInterrupt:
        logger.info("Process interrupted by user")
        sys.exit(1)
    except Exception as e:  # pylint: disable=broad-exception-caught
        # Reason: Main function top-level exception handler for any unexpected errors
        logger.error("Unexpected error in main: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
