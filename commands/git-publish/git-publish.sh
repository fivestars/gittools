#! /usr/bin/env bash

read -r -d '' HELP <<'HELP' || :
git-publish - Push your changes and creates a pull request

Requirements:
    Install the git-pull-request command

Usage:
        git publish  # equivalent to publish
     or $(_extract_desc install)
     or $(_extract_desc publish)

Operations:
$(_extract_help)

HELP

function help {
    : <<HELP
    Displays this help message.
HELP

    if [[ -n $1 ]]; then
        _extract_desc $1
        echo
        _extract_doc -h "$1"
    elif [[ -t 1 ]]; then
        eval "echo \"$HELP\"" | less
    else
        eval "echo \"$HELP\""
    fi
}

function _extract_desc {
    local cmd=$1
    echo "git publish ${cmd} $(_extract_doc -d ${cmd} | sed 's/^\s*//g')"
}

function _extract_help {
    while read cmd; do
        echo -e "\n    ${cmd}"
        _extract_doc -h ${cmd} | sed 's/^/    /g'
    done < <(grep '$(_extract_desc [-a-zA-Z0-9]\+)$' ${BASH_SOURCE} | sed 's/.* \(.*\))/\1/g')
}

function _extract_doc {
    local doc_type
    while getopts ":dh" OPT; do
        case $OPT in
            d) doc_type=DESC;;
            h) doc_type=HELP;;
        esac
    done
    shift $((OPTIND-1))
    type $1 | awk "NR==1,/<<${doc_type}/{next}/^${doc_type}/,NR==0{next}{print}"
}


function install {
    : <<DESC
    [--local] [--global]
DESC
    : <<HELP
    Installs 'git publish' as an alias.
        --local: The repository's aliases (default)
        --global: Your global aliases
HELP

    local token repo=false global=false choice
    for token in "$@"; do
        case $token in
            -l|--local) shift; repo=true;;
            -g|--global) shift; global=true;;
            "") ;;
            *) echo "Unknown option: $token"; return 1;;
        esac
    done
    $global || $core || repo=true

    src_abs_path=$(cd $(dirname $BASH_SOURCE) && pwd)/$(basename $BASH_SOURCE)

    if $repo; then
        git config alias.publish "!$src_abs_path" && \
            echo "Added \"publish\" to your repository's aliases."
    fi

    if $global; then
        git config --global alias.publish "!$src_abs_path" && \
            echo "Added \"publish\" to your global aliases."
    fi
}

function publish {
    : <<DESC
DESC
    : <<HELP
    Pushes your current feature branch and creates a pull request.

    This will create a new remote branch if the feature branch has not
    been pushed yet.

    If the pull request already exists, it will simply open the
    page in your browser.

    Set the git repo config value for hub.base to the default branch to
    create the pull request against.
HELP
    local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null || :)
    (
        set -e
        if [[ -z $upstream || -n $(git rev-list HEAD ^$upstream --) ]]; then \
            git push -u
        fi
        git pull-request "$@"
    )
}

case $1 in
    -*) ;;
    *) cmd=${1:-publish}; shift ||: ;;
esac
$cmd "$@"
