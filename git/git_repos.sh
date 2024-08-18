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
default_branch=master

function git_function() {
    echo "====================== $(pwd || true) ======================"
    git fetch --all
    repo_url=$(git config --get remote.origin.url)
    echo "${repo_url}"
    if git ls-remote --quiet --exit-code --heads "${repo_url}" "${default_branch}" >/dev/null; then
        echo Remote branch \'"${default_branch}"\' exists, checking out to it
        if ! git checkout -b "${default_branch}" --track origin/"${default_branch}" >/dev/null 2>&1; then
            git checkout "${default_branch}"
            git merge origin/"${default_branch}"
        fi
    else
        git checkout -b master --track origin/master 2>/dev/null
        echo Remote branch \'"${default_branch}"\' not exists, checking out to branch \'master\'
    fi
    echo
}

git_dir=$(pwd)
mkdir -p "${git_dir}"

for repo in ${repos_list}; do
    if [[ -d "${git_dir}/${repo}" ]]; then
        cd "${git_dir}/${repo}" || return
        git_function
    else
        git clone "${repo_base_url}/${repo}.git" "${git_dir}/${repo}"
        cd "${git_dir}/${repo}" || return
        git_function
    fi
done
