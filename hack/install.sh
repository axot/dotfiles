#!/usr/bin/env zsh

echo install zplug
export ZPLUG_HOME=$HOME/zplug
mkdir -p $ZPLUG_HOME
git clone https://github.com/zplug/zplug $ZPLUG_HOME

source ${ZDOTDIR:-${HOME}}/.zshrc
zplug install

echo install zshrc etc
rsync -av --progress ../.* $HOME/ --exclude .git --exclude .gitmodules

# need $HOME/.zimrc
echo install zim
git clone --recursive https://github.com/zimfw/zimfw.git ${ZDOTDIR:-${HOME}}/.zim
source ~/.zim/zimfw.zsh install

echo install vim plugins
vim +PlugClean +qall
vim +PlugInstall +qall

echo install done
echo switch to zsh with: chsh -s /path/to/zsh
