#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#############################################################################################################################
# Script Name: pulley.sh                                                                                                    #
# Author: Jeffrey Bednar                                                                                                    #
# Copyright (c) Illusion Interactive, 2011 - 2025.                                                                          #
#############################################################################################################################
# Date: Saturday, July 26th, 2025
# Description: Pulls latest changes from the remote main branch for all provided repo urls.
#
# Enable execution: chmod +x pulley.sh
#
# For each repo in the list:
#   - Clone it if missing.
#   - Fetch updates from remote.
#   - Check if remote 'main' branch exists.
#   - Checkout 'main' branch.
#   - Pull latest changes with rebase and autostash.
#
# Skips folders that are not valid git repos or have no 'main' branch.
# Prints status messages throughout.
#############################################################################################################################
declare -A repo_urls=(
    ["Gatherers-Legacy"]="https://github.com/Broosky/Gatherers-Legacy.git"
    ["Gatherers"]="https://github.com/Broosky/Gatherers.git"
    ["Patchworks"]="https://github.com/Broosky/Patchworks.git"
    ["7Driver"]="https://github.com/Broosky/7Driver.git"
    ["Workers"]="https://github.com/Broosky/Workers.git"
    ["Lumenary"]="https://github.com/Broosky/Lumenary.git"
    ["Wattson"]="https://github.com/Broosky/Wattson.git"
    ["Squarely"]="https://github.com/Broosky/Squarely.git"
    ["II86"]="https://github.com/Broosky/II86.git"
)
#############################################################################################################################
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}
#############################################################################################################################
clone_repo() {
    local repo_name=$1
    local repo_url=$2
    local repo_path=$3

    echo "--> Cloning $repo_name from $repo_url -->"
    git clone "$repo_url" "$repo_path" || {
        echo "!!! Failed to clone $repo_name !!!"
        return 1
    }
    return 0
}
#############################################################################################################################
fetch_and_pull_main() {
    local repo_name=$1
    local repo_path=$2

    cd "$repo_path" || {
        echo "!!! Cannot enter directory $repo_path !!!"
        return 1
    }

    echo "--> Fetching updates for $repo_name -->"
    git fetch --all --prune

    if git show-ref --verify --quiet refs/remotes/origin/main; then
        echo "--> 'main' branch exists, checking out -->"
        git checkout main &>/dev/null || {
            echo "!!! Could not checkout 'main' branch in $repo_name !!!"
            return 1
        }

        echo "--> Pulling latest changes for 'main' -->"
        git pull --rebase --autostash origin main
    else
        echo "--> No 'main' branch found in remote for $repo_name, skipping pull -->"
    fi
}
#############################################################################################################################
main() {
    local script_dir
    local root_dir

    script_dir=$(get_script_dir)
    root_dir=$(dirname "$script_dir")

    echo "--> Syncing 'main' branches of repositories in $root_dir -->"

    for repo_name in "${!repo_urls[@]}"; do
        local repo_url=${repo_urls[$repo_name]}
        local repo_path="$root_dir/$repo_name"

        echo ""
        echo "--> Processing repository: $repo_name -->"

        if [ ! -d "$repo_path" ]; then
            clone_repo "$repo_name" "$repo_url" "$repo_path" || continue
        fi

        if [ -d "$repo_path/.git" ]; then
            fetch_and_pull_main "$repo_name" "$repo_path"
        else
            echo "!!! Directory $repo_path exists but is not a git repository, skipping !!!"
        fi
    done

    echo ""
    echo "--> Done."
}
#############################################################################################################################
main "$@"
