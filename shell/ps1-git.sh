#! /bin/sh 
# Source from .bashrc
#
# Provides:
#   ps1-git: Generates a prompt string summarizing the state of the current git repo.
#
# Example (in .bashrc):
# . /path/to/ps1-git.sh # use some sort of non-relative path
# export PS1='\n\u\[\e[1;37m\]@\[\e[1;36m\]\h:\[\e[1;33m\]\w $(ps1-git -l -s"|")\[\e[1;37m\]\n$\[\e[0m\] '

# Display the current git branch status information
function ps1-git() {

    # Record the state of the last command-line command
    RESULT=$?

    local LAZY=
    local SHORT=

    local OPTIND=
    local OPTARG=
    local OPTERR=
    local OPT=
    while getopts :ls: OPT; do
	case $OPT in
	    l) LAZY=1;;
	    s) SHORT=$OPTARG;;
	    ?) case $OPTARG in
		s) SHORT='|';;
               esac;;
	esac
    done
    shift $((OPTIND - 1))

    # Quick check to see if we're in a git repository
    local SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
    local DIR=$( builtin cd -P "$( dirname "$SOURCE" )" && pwd )
    local GIT_DIR=
    GIT_DIR=$($DIR/in-git.sh)/.git || return 0

    # Only do the work under certain conditions. It's cached for later
    if ( [[ ! -e $GIT_DIR/.prompt_last ]] || # ( first time in this repo ||
	    [[ -z $LAZY ]] ||	             #   we're forcing it ||
					     #   the last command was a successful git command )
	    ( [[ $RESULT == 0 ]] && history 1 | grep "git *\(status\|add\|commit\|push\|pull\|fetch\|rebase\|merge\|checkout\|reset\)" >/dev/null ) 
	); then
		
	# Determine the current branch
	local BRANCH=$(git branch | grep '^*' | sed 's/* //')
	if [[ "$BRANCH" == "(no branch)" ]]; then
	    local REFLOG=$(git reflog -n1)
	    local REFHASH=${REFLOG%% *}
	    local REFNAME=${REFLOG##* }
	    if [[ ${REFNAME:0:${#REFHASH}} == ${REFHASH} ]]; then
		BRANCH="(headless on ${REFHASH})"
	    else
		BRANCH="(headless on ${REFNAME})"
	    fi
	fi

	# Determine our upstream branch
	local UPSTREAM=
	UPSTREAM=$(git rev-parse --abbrev-ref @{u} 2>/dev/null) || UPSTREAM=

        # Collect our statii in this empty array
	local STATII=();
	local NEW=$(git ls-files -o --exclude-standard $GIT_DIR/.. | wc -l)
	local EDITS=$(git ls-files -dm $GIT_DIR/.. | wc -l)
	local STAGED=$(git diff --name-only --cached | wc -l)

	# How do we display changes in our working directory and index?
	if [[ -z $SHORT ]]; then
	    # Full, spelled-out file states
	    [[ $NEW != 0 ]] && STATII=( "${STATII[*]}" "$NEW-new" )
	    [[ $EDITS != 0 ]] && STATII=( "${STATII[*]}" "$EDITS-edits" )
	    [[ $STAGED != 0 ]] && STATII=( "${STATII[*]}" "$STAGED-staged" )
	else
            # Alternate, disabled view of outstanding changes
	    STATII=( "${NEW}${SHORT}${EDITS}${SHORT}${STAGED}" )
	fi
	
	# Display any divergence from our upstream branch
	if [[ -n $UPSTREAM && -n $BRANCH ]] && echo $BRANCH | grep -vq '(.*)'; then
	    local BEHIND=$(git rev-list ^$BRANCH $UPSTREAM | wc -l)
	    local AHEAD=$(git rev-list $BRANCH ^$UPSTREAM | wc -l)

	    [[ $BEHIND != 0 ]] && STATII=( "${STATII[*]}" "${BEHIND}v" )
	    [[ $AHEAD != 0 ]] && STATII=( "${STATII[*]}" "${AHEAD}^" )
	fi

	# Reduce the array to a string
	STATII=$(echo -n ${STATII[*]})
	
	# Display branch information (upstream, too, if available)
	local BRANCHES=
	if [[ -z $BRANCH ]]; then
	    BRANCHES="[master]"
	elif [[ -z $UPSTREAM ]]; then
	    BRANCHES="[$BRANCH]"
	else
	    BRANCHES="[$BRANCH->$UPSTREAM]"
	fi
	
	# Write the prompt string to cache file
	echo "${BRANCHES}(${STATII})" > $GIT_DIR/.prompt_last
	    
	# Color code to white to let us know this is a fresh status
	echo -en '\e[1;37m'
    else		
        # We'll be displaying a stale status in gray
	echo -en '\e[0;37m'
    fi

    # Display the most recently generated status
    cat $GIT_DIR/.prompt_last
}

ps1-git $@ >/dev/null
