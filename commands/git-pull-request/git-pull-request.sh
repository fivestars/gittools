#! /usr/bin/env bash

read -r -d '' HELP <<'HELP' || :
git-pull-request - Create a github pull request for your current branch

Requirements:
    Install and configure the 'hub' command (https://github.com/github/hub)
    Install jq (https://stedolan.github.io/jq)

Usage:
       git pull-request  # equivalent to create
    or $(_extract_desc install)
    or $(_extract_desc create)

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
    echo "git pull-request ${cmd} $(_extract_doc -d ${cmd} | sed 's/^\s*//g')"
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
    Installs 'git pull-request' as an alias.
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
        git config alias.pull-request "!$src_abs_path" && \
            echo "Added \"pull-request\" to your repository's aliases."
    fi

    if $global; then
        git config --global alias.pull-request "!$src_abs_path" && \
            echo "Added \"pull-request\" to your global aliases."
    fi
}

function create {
    : <<DESC
    [-b] <base branch>
DESC
    : <<HELP
    Creates a github pull request for the current feature branch.

    If the pull request already exists, it will simply open the
    page in your browser.

    Set the git repo config value for hub.base to the default branch to
    create the pull request against.
HELP
    local base=$(git config hub.base)
          base=${base:-master}
    local owner=$(git config --get remote.origin.url)
          owner=${owner#*:}
          owner=${owner%/*}
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local api_credentials=$(
        cat ~/.config/hub |
        python -c 'import yaml, json, sys; print json.dumps(yaml.load(sys.stdin))' |
        jq '.["github.com"][0] | "\(.["protocol"])://\(.["user"]):\(.["oauth_token"])"' |
        xargs -n1
    )
    local api_url=$(git config --get remote.origin.url)
          api_url=${api_url#git@}
          api_url=${api_url%.git}
          api_url=${api_url/://}
          api_url=${api_url/github.com/github.com/repos}
          api_url=$api_credentials@api.${api_url}
    (
        set -e
        export GIT_EDITOR="${HUB_EDITOR:-$GIT_EDITOR}"

        while getopts ":b:" OPT; do
            case $OPT in
                b) base=$OPTARG;
            esac
        done
        shift $((OPTIND - 1))

        pulls=$(curl -G "$api_url/pulls" \
                --data-urlencode "base=$base" \
                --data-urlencode "head=$owner:$branch" 2>/dev/null)
        if [[ $(jq 'length' <<<$pulls ) -eq 0 ]]; then
            hub pull-request -o -b $base $*
        else
            hub browse -- pull/$(jq '.[0]["number"]' <<<$pulls | xargs -n1)
        fi
    )
}

case $1 in
    -*) ;;
    *) cmd=${1:-create}; shift ||: ;;
esac
$cmd "$@"
