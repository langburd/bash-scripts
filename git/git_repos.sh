#!/bin/bash

# Script for cloning/updating the list of repos from one git server
#
# Usage:
# - Configure path to the cloned repos in 'git_dir' variable.
# - Set variable 'repo_base_url' with URL of your username (GitHub) or some project (GitLab) - the 'base URL' that contains all repos.
# - Put list of names of repos in 'list.txt' or define path to your file with names in the 'repos_list' variable.
# - If the default branch that is used in your organization is not 'master' define the variable 'default_branch'.
# - Run the script.

gh_org=langburd
repo_base_url=git@github.com:${gh_org}
repos_list=$(gh repo list "${gh_org}" -L 1000 --json name --jq '.[].name')
# default_branch=master
git_dir="/Users/avi.langburd/git/ddyy" # "$(pwd)/git_repositories"
mkdir -p "${git_dir}"

for repo in ${repos_list}; do
    echo "====================== ${git_dir}/${repo} ======================"
    if [[ -d "${git_dir}/${repo}" ]]; then
        cd "${git_dir}/${repo}" || return
        git fetch --all --tags --prune --jobs=10
        git pull
    else
        git clone "${repo_base_url}/${repo}.git" "${git_dir}/${repo}"
    fi
done
