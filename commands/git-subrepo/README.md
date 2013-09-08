    Description
        git-subrepo is an external git repository dependency tool and can be used
        as an alternative to git-submodule and git-subtree. It is intended to be a
        drop-in replacement for git-submodule, albiet with less "black magic" under
        the hood.
    
        git-subrepo allows you to have a parent project with one or more external
        dependencies (other git repos). The external repos have the option of being
        "pinned" to particular branches, tags or commits. Upon running
        "git-subrepo update", the dependencies will be synced from their respective
        remote repositories.
    
        It differs with git-submodule in that git-subrepo enables a looser coupling
        of parent-to-child repositories and attempts to alleviate the pain of
        forgetting to commit and push a child repository before pushing a parent
        repository.
    
    Usage:
            git subrepo [<general options>] [list [-v|--verbose] [<path>...]]
        or: git subrepo [<general options>] install [--local] [--global] [--core]
        or: git subrepo [<general options>] uninstall [--local] [--global] [--core]
        or: git subrepo [<general options>] add [--no-recurse] [-f|--force]
                                                [(-p|--pin) <pin>] <repository>
                                                [<path>]
        or: git subrepo [<general options>] rm [-d|--delete] [<path>...]
        or: git subrepo [<general options>] checkout <path> [<pin>]
        or: git subrepo [<general options>] update [-i <indent>] [--no-recurse] 
                                                [--no-command] [--top] [--rebase]
                                                [(-p|--pin) (c|k|o|s)] [<path>...]
        or: git subrepo [<general options>] postupdate [--set] [--clear]
                                                [<command>]
        or: git subrepo [<general options>] foreach <command> [<path>...]
        or: git subrepo [<general options>] publish [-f] [-m <message>]
        or: git subrepo [<general options>] help
    
    Files:
        .gitrepos
            This is where git-subrepo stores its tracking information. Like
            .gitignore, it is intended to be committed along with any other file
            in your repository. It follows the git config file format and can be
            manipulated with git-config.
    
        .gitignore
            git-subrepo attempts to keep the .gitignore file synchronized with the
            .gitrepos entries. sub-repo directories will be ignored.
    
    General Options:
        -c|--color (a|auto|y|yes|n|no)
            Controls whether special color control characters are written to stdout.
    
            a|auto: Default, let git-subrepo attempt to detect
                whether or not to output colors.
            y|yes: Force color output.
            n|no: Disable color output.
    
        -f|--file
            Use the given file rather than the local .gitrepos file. For operations
            that recurse to sub-repos, this file is only used for the top-levelrepo.
            The sub-repos will use their standard .gitrepos file.
    
        -q|--quiet
            Suppress stdout output.
    
        -r|--retry <num>
            Attempt remote-related git commands up to <num> times. Wait 2 seconds
            before the second attempt, 4 before the third, 8 before the fourth, and
            so on. Default value is 3.
    
    Common Arguments:
    	<path>...
    	    This indicates that the command will operate over a subset of the
    	    sub-repos. If not specified, the command will iterate over the complete
            set of sub-repos.
    
            The format of <path>... is a list of path-strings, separated by spaces.
    
            A path-string can be one of the following formats:
                
                path/to/sub-repo
                    A single sub-repo
              
                path/to/sub-repo...
                    All sub-repos after this one, inclusive
                
                ...path/to/sub-repo
                    All sub-repos up to this one, inclusive
                
                path/to/sub-repo-a...path/to/sub-repo-b
                    All sub-repos between the two, inclusive
    
    Operations:
        list
            Lists the current sub-repos for this repository.
                
                -v|--verbose
                    Displays the sub-repo's remote URL as well
    
        install
            Installs 'git-subrepo' into any of three locations.
                
                --local
                    The repository's aliases (default)
    
                --global
                    Your global aliases
                
                --core
                    Copies this file into this machine's git core directory. Any
                    'subrepo' aliases will no longer be effective.
    
        uninstall
            Undoes the effects of 'install'.
    
        add
            Adds a new repository as a sub-repo. This will clone the repository to
            <path> and create an entry in the .gitrepos file.
     
                -f|--force
                    If the <path> already exists, continue to update the .gitrepos
                    file and leave the directory alone.
    
                -p|--pin <pin>
                    The repository will be checked out to <pin>, and it will be
                    recorded in the sub-repo's .gitrepos entry.
    
                --no-recurse
                    By default, git-subrepo will recursively descend into the new
                    sub-repo and perform a 'git-subrepo update' on them (also
                    recursive). Use this if you only want to clone this new
    				sub-repo but none of its sub-repos.
    
        rm
            Removes a sub-repo from this repository. This removes the sub-repo's
            entry from the .gitrepos file.
    
                -d|--delete
                    the sub-repo's directory will be removed from the working
                    directory as well.
    
        checkout
            Checks out a sub-repo to the given <pin>. This pin will be recorded in
            the sub-repo's .gitrepos entry. If no <pin> is given, the sub-repo's pin
            value will be cleared from the .gitrepos file.
    
                -b
                    Attempt to create a new branch with name <pin>
    
        update
            Clones any new repositories found in the .gitrepos file, or just
            <path>... sub-repos if provided, and pulls down any changes for the
            existing sub-repos. If the sub-repo's remote repository differs from
            the one in the .gitrepos file and there are unpushed changes in that
            sub-repo, you will be prompted to resolve these changes before
            continuing. If a the sub-repo has a pin in the .gitrepos file and it
            differs from the sub-repo's currently checked out pin, you will be
            given a choice of how to handle it: switch, keep, overwrite.
    
                --no-recurse
                    By default, git-subrepo will recursively descend into each
                    sub-repo and perform a 'git-subrepo update' on them (also
                    recursive). Use this if you only want to update this top-level
    				repo.
    
                --no-command
                    By default, git-subrepo will execute any command configured by
                    postupdate. Prevent that behavior with this.
    
                --top
                    Perform a pull on this top-level repo first.
    
                --rebase
                    Perform a rebase rather than a merge when pulling commits from
                    the sub-repos' origins. Also used with the --top pull.
    
                --pin (c|k|o|s)
                    Use this value rather than waiting for user input when prompted
                    to handle a difference in .gitrepos pin and current pin.
    
        postupdate
            Configures commands to be run after a successful update. Call with no
            options or command to list the currently configured commands. Call with
            <command> but no options to simply add a command to the list.
    
                --set
                    Replace all currently configured commands with the one provided
                    on the command line.
    
                --clear
                    Remove all currently configured commands.
    
        publish
            Safely pushes the current .gitrepos file. It iterates through the
            sub-repo list in the .gitrepos file and verifies that they are checked
            out locally and that each pin(if present) exists in its remote
            repository.
            
            You are then prompted to continue with the add-commit-push of the
            .gitrepos file. This operation will not proceed unless the index
            (stage) is clean.
    
                 -f
                     The prompt will be suppressed, and it will proceed
                     as if you had entered 'y'.
    
                 -m
                     The commit message. Defaults to 'Updating sub-repos'
    
        foreach
            Execute <command> for each sub-repo in the .gitrepos file or for each
            <path>.
    
        help
            Displays this help message.
