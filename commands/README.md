### git-subrepo
This is an alternative to git-submodule that allows a looser coupling between parent and child projects.

For instance, one can have a sub-repo track a particular branch rather than be pinned to a specific commit. Updating the parent project will update the children projects to the heads of their respective branches.

### git-hooks
This is a tool to facilitate git hook management

You can now store your hooks within the repository itself and simply reference them from a (provided) multiplexer hook installed in the .git/hooks directory.
