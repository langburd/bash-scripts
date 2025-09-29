#!/usr/local/bin/python3
# pylint: disable=invalid-name
# Reason: File name uses hyphens for compatibility with existing dependencies
"""
GitLab Repository Cloning Script

This script connects to a GitLab instance and clones all repositories from
specified groups. It uses the GitLab API to list projects and clones them
using git commands.
"""

import os

import gitlab  # type: ignore[import-untyped]

current_dir = os.getcwd()
dir_to_clone = current_dir + "/gitlab-tl-ash1"

# private token or personal token authentication (self-hosted GitLab instance)
GITLAB_URL = "https://gitlab-tl-ash1.cyren.io"
gitlab_token = os.getenv("GITLAB_AUTH_TOKEN")
gl = gitlab.Gitlab(GITLAB_URL, private_token=gitlab_token)  # type: ignore[attr-defined]

# List gitlab projects
gitlab_projects = set()
projects = gl.projects.list(all=True)
ROOT_GROUP = ""
excluded_projects = ["ffdb"]
for project in projects:
    # comment this line in order to clone also user's repositories
    if project.namespace["kind"] == "group":
        if (
            project.namespace["full_path"].startswith(ROOT_GROUP)
            and project.path not in excluded_projects
        ):
            print("=" * 75)
            print(project.name)
            print(project.namespace["full_path"])
            print(project.ssh_url_to_repo)
            os.system(
                "mkdir -p "
                + dir_to_clone
                + "/"
                + project.namespace["full_path"]
                + '; cd "$_"; [ -d "'
                + project.path
                + '" ] && cd '
                + project.path
                + " && git checkout "
                + project.default_branch
                + " && git fetch --all --tags -f && git pull -f || git clone "
                + project.ssh_url_to_repo
            )
