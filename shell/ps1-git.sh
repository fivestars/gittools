#! /bin/sh 
# Source from .bashrc
#
# Provides:
#   ps1-git: Generates a prompt string summarizing the state of the current git repo.
#
# Example (in .bashrc):
# . /path/to/ps1-git.sh # use some sort of non-relative path
# export PS1='\n\u\033[1;37m@\033[1;36m\h:\033[1;33m\w $(ps1-git -l -s"|")\033[1;37m\n$\033[0m '

function ps1-git() {

	# Record the state of the last command-line command
	RESULT=$?

	local LAZY WAIT="5 minutes ago" SHORT BEFORE='\033[1;37m' BEFORE_STALE='\033[0;37m' AFTER AFTER_STALE STALE GIT_DIR
	local OPTIND OPTARG OPTERR OPT
	while getopts :lw:WsS:c:b:B:a:A: OPT; do
		case $OPT in
			l) LAZY=1;;
			w) WAIT="$OPTARG ago";;
			W) WAIT=;;
			s) SHORT='|';;
			S) SHORT=$OPTARG;;
			b) BEFORE=$OPTARG;;
			B) BEFORE_STALE=$OPTARG;;
			a) AFTER=$OPTARG;;
			A) AFTER_STALE=$OPTARG;;
		esac
	done
	shift $((OPTIND - 1))
	
	# Quick check to see if we're in a git repository
	local GIT_DIR=
	if [[ $(git rev-parse --is-inside-git-dir 2>/dev/null) != false ]] || \
		! GIT_DIR=$(git rev-parse --git-dir); then
		return 0
	fi

	# Only do the work under certain conditions. It's cached for later.
	if ( [[ ! -e $GIT_DIR/.prompt_last ]] ||	# ( first time in this repo ||
		 [[ -z $LAZY ]] ||						#   we're forcing it ||
		 										#   ( the last command was a successful git command ) ||
		 ( [[ $RESULT == 0 ]] && history 1 | grep "git *\(status\|add\|commit\|push\|pull\|fetch\|rebase\|merge\|checkout\|reset\)" >/dev/null ) || 
		 										#   ( the prompt is out of date ) )
		 ( [[ -n $WAIT ]] && [[ $(stat -c %Y $GIT_DIR/.prompt_last) < $(date -d "$WAIT" +%s) ]] ) ); then

		# Determine the current branch
		local BRANCH=$(git branch | grep '^*' | sed 's/* //')
		if [[ "$BRANCH" == "(no branch)" ]]; then
			local REFLOG=$(git reflog -n1)
			local REFHASH=${REFLOG%% *}
			local REFNAME=${REFLOG##* }
			if [[ ${REFNAME:0:${#REFHASH}} == ${REFHASH} ]]; then
				BRANCH="(detached at ${REFHASH})"
			else
				BRANCH="(detached at ${REFNAME})"
			fi
		fi

		# Determine our upstream branch
		local UPSTREAM
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
			local BEHIND=$(git rev-list ^refs/heads/$BRANCH $UPSTREAM | wc -l)
			local AHEAD=$(git rev-list refs/heads/$BRANCH ^$UPSTREAM | wc -l)

			[[ $BEHIND != 0 ]] && STATII=( "${STATII[*]}" "${BEHIND}v" )
			[[ $AHEAD != 0 ]] && STATII=( "${STATII[*]}" "${AHEAD}^" )
		fi

		# Reduce the array to a string
		STATII=$(echo -n ${STATII[*]})
		
		# Display branch information (upstream, too, if available)
		local BRANCHES
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
		echo -en ${BEFORE}
	else
		# We're going to display a cached status
		CACHED=1

		# We'll be displaying a cached status in gray
		echo -en ${BEFORE_STALE}
	fi

	# Display the most recently generated status
	cat $GIT_DIR/.prompt_last


	[[ -z ${CACHED} ]] && echo -en ${AFTER} || echo -en ${AFTER_STALE}

	return $RESULT
}

ps1-git $@ >/dev/null
