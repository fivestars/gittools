# Git Hooks #

These scripts facilitate git repository hook management. They ultimately
allow you to register multiple scripts for a single hook. Support is
provided for running a hook's scripts in parallel as well.

# Getting Started #

1. Navigate to your repository
2. Execute the install script

    $ path/to/hooks/install <scripts...>

This creates a .githooks directory in your repository and installs the 
multiplexing scripts into the .git/hooks directory. Any existing
hooks will have been copied to the newly created .githooks directory
and now have the "-moved" suffix.

# Usage #
## Hook names ##
Hooks must follow a simple naming convention.

    <standard git hook name>-<suffix>

## Hook contents ##
Hooks must be bash scripts. If you have scripts in another language, create a small bash script that delegates to your existing script. A possible convention would be to create a sub-directory in .githooks corresponding to the standard git hook and place your non-bash scripts in there.

## Hook locations ##
Any hooks placed into the .githooks directory are enabled by default.
Hooks located elsewhere must be installed with the install script.

## Disabling hooks ##
Use git config:

    git config --bool  hooks.<standard git hook name>.<hook script name>.enabled false

## Parallel hooks ##
If your hooks can be run in parallel, you can enable this behavior by doing the following:

    git config hooks.<standard git hook name>.parallel <num>

Where <num> is the max number of concurrent scripts you wish to allow for the hook. Specify a value of 0 if you wish to use number of CPU on the machine.

Hook scripts can enforce synchronous execution by calling the exposed bash function **prevent-parallel**

    #! /bin/bash
    prevent-parallel
    ...hook contents...

This will cause the hook to fail if the parallel config value is set to anything but 1.
