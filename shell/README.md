### ps1-git.sh
Provides _ps1-git_, a function that can be invoked from within your custom PS* strings.

It produces a quick summary of your repo state including:

* branch name
* remote name
* counts of (new|modified|staged) files
* the divergence between your local branch and its remote tracking branch.

####
    ~/git/client[(detached at 0.6.0-all)](5|0|0)
    $ echo $PS1
    \w$(ps1-git -l -s)\[\e[1;37m\]\n$\[\e[0m\]
