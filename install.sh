#!/bin/bash

# Figure out where this file is located.
P="$( cd "$(dirname "$0")" ; pwd -P )"
echo $P

# Update modules
git submodule update --init --recursive

# build clang
pushd  $P/vim/bundle/YouCompleteMe
    ./install.py --clang-completer
popd

# ln uses VERSION_CONTROL to indicate how to create backup files.
VERSION_CONTROL=numbered

# create links
#ln -s $P/inputrc ~/.inputrc
#ln -s $P/vim ~/.vim
#ln -s $P/tmux.conf ~/.tmux.conf
#ln -s $P/ideavimrc ~/.ideavimrc
#ln -s $P/tmux.conf ~/.tmux.conf

echo "Be sure to install tools under bash..."
