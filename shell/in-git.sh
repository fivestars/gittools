#! /bin/sh

while [[ ! -e .git && $PWD != '/' ]]; do
    cd ..
done

[[ -e .git ]] && echo $PWD
