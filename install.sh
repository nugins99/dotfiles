
git submodule update --init --recursive 

pushd  vim/bundle/YouCompleteMe
./install.py --clang-completer
popd

ln -sf inputrc ~/.inputrc
ln -sf vim ~/.vim
