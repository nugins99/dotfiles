#!/bin/bash 

P="$( cd "$(dirname "$0")" ; pwd -P )"
echo $P

# Update modules 
git submodule update --init --recursive 

# build clang
pushd  $P/vim/bundle/YouCompleteMe
    ./install.py --clang-completer
popd

# backup existing files
if [ -f ~/.inputrc ] ; then 
    mv  ~/.inputrc  ~/.inputrc.dotfiles-backup
fi

if [ -f ~/.vim ] ; then 
    mv  ~/.vim ~/.vim.dotfiles-backup
fi

# create links
ln -sf $P/inputrc ~/.inputrc
ln -sf $P/vim ~/.vim
ln -sf $P/tmux.conf ~/.tmux.conf
ln -sf $P/ideavimrc ~/.ideavimrc
