#!/bin/bash

# Figure out where this file is located.
P="$( cd "$(dirname "$0")" ; pwd -P )"
echo $P

# Update modules
git submodule update --init --recursive

# build clang
YCM_DIR=$P/vim/pack/plugins/start/YouCompleteMe
cd $YCM_DIR
./install.py --clang-completer
cd $P

# ln uses VERSION_CONTROL to indicate how to create backup files.
VERSION_CONTROL=numbered

# create links
ln -sf $P/inputrc ~/.inputrc
ln -sf $P/vim ~/.vim
ln -sf $P/tmux.conf ~/.tmux.conf
ln -sf $P/ideavimrc ~/.ideavimrc
ln -sf $P/tmux.conf ~/.tmux.conf
ln -sf $P/gitconfig  ~/.gitconfig

echo "Be sure to install tools under bash..."

echo "source $P/bashrc" >> ~/.bashrc
