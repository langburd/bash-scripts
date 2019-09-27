#!/bin/bash

git_dir=`pwd`
repo_base_url=git@github.com:langburd
repos_list=$(cat `pwd`/list.txt)
remote_branch=newbranch

mkdir -p $git_dir
function git_function() {
    git fetch --all
    declare -a remote_branches
    remote_branches=$(git branch -r | cut -c10- | grep -v HEAD)
    for i in "${remote_branches[@]}"; do
        repo_url=$(git config --get remote.origin.url)
        if git ls-remote --quiet --exit-code --heads $repo_url $remote_branch >/dev/null; then
            echo Remote branch \'$remote_branch\' exists, checking out to it
            # git branch -D origin/$remote_branch 2>/dev/null
            git checkout -b $remote_branch --track origin/$remote_branch 2>/dev/null
            # git branch -D master 2>/dev/null
        else
            git checkout -b master --track origin/master 2>/dev/null
            echo Remote branch \'$remote_branch\' not exists, checking out to branch master
            # git branch -D $remote_branch 2>/dev/null
        fi
    done
}

for repo in $repos_list
do
    if [ -d "$git_dir/$repo" ]; then
        cd $git_dir/$repo
        echo ======================$(pwd)======================
        git_function
        echo 
    else 
        git clone $repo_base_url/$repo.git $git_dir/$repo
        cd $git_dir/$repo
        echo ======================$(pwd)======================
        git_function
        echo 
    fi
done

