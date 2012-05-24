#! /bin/sh 
# Source from .bashrc
#
# Provides:
#   in_git: Succeeds and prints repo path if current working directory is within a git repo.
#   ps1-git: Generates a prompt string summarizing the state of the current git repo.
#
# Example (in .bashrc):
# . ~/devtools/workflow/ps1-git.sh
# export PS1="\n\u\[\e[1;37m\]@\[\e[0;33m\]\h:\[\e[1;34m\]\w\$(ps1_git --lazy)\[\e[1;37m\]\n\$\[\e[0m\] "

# Display the current git branch status information
function ps1-git() {

    local SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
    local DIR=$( builtin cd -P "$( dirname "$SOURCE" )" && pwd )

    # Record the state of the last command-line command
    RESULT=$?

    # Quick check to see if we're in a git repository
    local GIT_DIR;
    if ! GIT_DIR=$($DIR/in-git.sh)/.git; then
	return
    fi

    # Create a 'last time updated' file if this is
    # the first time we're in this directory
    if [[ ! -e $GIT_DIR/.prompt_last ]]; then
	touch --date="2 days ago" $GIT_DIR/.prompt_last
    fi
    
    # Create file in the past to see if we've been here since then
    touch --date="1 day ago" $GIT_DIR/.prompt_bounce

    # If we haven't and "git status" is successful, do the complete examination
    if ( [[ $GIT_DIR/.prompt_bounce -nt $GIT_DIR/.prompt_last ]] || # ( info is out of date or
	    [[ "$1" != "--lazy" ]] ||				    #   we're forcing it or
								    #   the last command was a successful git command ) and
	    ( [[ $RESULT == 0 ]] && history 1 | grep "git *\(status\|add\|commit\|push\|pull\|fetch\|rebase\|merge\|checkout\|reset\)" >/dev/null ) 
	) && git status >/tmp/tmp.git_status 2>/dev/null; then			# we succesfully fetched and grabbed the current status
		
        # Collect our statii in this empty array
	local STATII=();
	cat /tmp/tmp.git_status | grep "# Untracked files:" >/dev/null && STATII=( "${STATII[*]}" "new" )
	cat /tmp/tmp.git_status | grep "# Changes not staged for commit:" >/dev/null && STATII=( "${STATII[*]}" "edits" )
	cat /tmp/tmp.git_status | grep "# Changes to be committed:" >/dev/null && STATII=( "${STATII[*]}" "staged" )
	
	if cat /tmp/tmp.git_status | grep "# Your branch is behind" >/dev/null; then
	    STATII=( "${STATII[*]}" $(cat /tmp/tmp.git_status | grep "# Your branch is behind" | sed 's/.*by \([0-9]\+\) commit.*/\1v/' ) )
	fi
	
	if cat /tmp/tmp.git_status | grep "# Your branch is ahead" >/dev/null; then
	    STATII=( "${STATII[*]}" $(cat /tmp/tmp.git_status | grep "# Your branch is ahead" | sed 's/.*by \([0-9]\+\) commit.*/\1^/' ) )
	fi
	
	if cat /tmp/tmp.git_status | grep "# Your branch.*have diverged" >/dev/null; then
	    STATII=( "${STATII[*]}" $(cat /tmp/tmp.git_status | grep "# and have " | sed 's/.*\s\([0-9]\+\)\s.*\s\([0-9]\+\).*/\1^ \2v/') )
	fi
	
	# Reduce the array to a string
	STATII=$(echo -n ${STATII[*]})
	
	# Determine the branch we're on and how to display it
	local BRANCH=$(cat /tmp/tmp.git_status | grep "^# On branch" | sed -e "s/^# On branch //")
	if [[ $BRANCH != master ]]; then
	    BRANCH=$(echo "[$BRANCH]")
	else
	    BRANCH=;
	fi
	
	# Write the prompt string to cache file
	echo " ${BRANCH}(${STATII})" > $GIT_DIR/.prompt_last
	    
	# Color code to white to let us know this is a fresh status
	echo -en "\e[1;37m"
    else		
        # We'll be displaying a stale status in gray
	echo -en "\e[0;37m"
    fi

    # Display the most recently generated status
    cat $GIT_DIR/.prompt_last
}

ps1-git

