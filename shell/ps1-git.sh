#! /bin/sh 
# Source from .bashrc
#
# Provides:
#   ps1_git_in_git: Succeeds and prints repo path if current working directory is within a git repo.
#   ps1_git: Generates a prompt string summarizing the state of the current git repo.
#
# Example (in .bashrc):
# . ~/devtools/workflow/ps1-git.sh
# export PS1="\n\u\[\e[1;37m\]@\[\e[0;33m\]\h:\[\e[1;34m\]\w\$(ps1_git --lazy)\[\e[1;37m\]\n\$\[\e[0m\] "


# Determine if we're in a git working directory, and
# if so, return the location of the .git directory
function ps1_git_in_git () {
    local START_DIR=$PWD
    while [[ ! -e .git && $PWD != $HOME && $PWD != '/' ]]; do
      cd ..
    done

    if [ -e .git ]; then
      echo $PWD
      cd $START_DIR
    else
      cd $START_DIR
      return 1
    fi
}

# Display the current git branch status information
function ps1_git() {
	# Record the state of the last command-line command
	RESULT=$?

	# Quick check to see if we're in a git repository
	local GIT_DIR;
	if ! GIT_DIR=$(ps1_git_in_git)/.git; then
		return
	fi

	# Create a 'last time updated' file if this is
	# the first time we're in this directory
	if [[ ! -e $GIT_DIR/.prompt_last ]]; then
		touch $GIT_DIR/.prompt_last
	fi
	
	# Create file in the past to see if we've been here since then
	touch --date="1 day ago" $GIT_DIR/.prompt_bounce
	
	# If we haven't and "git status" is successful, do the complete examination
	if ( [[ $GIT_DIR/.prompt_bounce -nt $GIT_DIR/.prompt_last ]] || # ( info is out of date or
		[[ "$1" != "--lazy" ]] ||				#   we're forcing it or
									#   the last command was a successful git command ) and
		 ( [[ $RESULT == 0 ]] && history 1 | grep "git *\(status\|add\|commit\|push\|pull\|merge\|checkout\|reset\)" >/dev/null ) 
	   ) && git fetch 2>/dev/null && git status >/tmp/tmp.git_status 2>/dev/null; then			# we succesfully fetched and grabbed the current status
			
		# Collect our statii in this empty array
		local STATII=();
		cat /tmp/tmp.git_status | grep "# Untracked files:" >/dev/null && STATII=( "${STATII[*]}" "new" )
		cat /tmp/tmp.git_status | grep "# Changes not staged for commit:" >/dev/null && STATII=( "${STATII[*]}" "edits" )
		cat /tmp/tmp.git_status | grep "# Changes to be committed:" >/dev/null && STATII=( "${STATII[*]}" "staged" )
		cat /tmp/tmp.git_status | grep "# Your branch is behind" >/dev/null && STATII=( "${STATII[*]}" "v" )
		cat /tmp/tmp.git_status | grep "# Your branch is ahead" >/dev/null && STATII=( "${STATII[*]}" "^" )
		cat /tmp/tmp.git_status | grep "# Your branch.*have diverged" >/dev/null && STATII=( "${STATII[*]}" "<" )
		
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

ps1_git

