#!/usr/bin/env zsh

echo install zim first
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
source ${ZDOTDIR:-${HOME}}/.zlogin

echo install zplug
export ZPLUG_HOME=$HOME/zplug
mkdir -p $ZPLUG_HOME
git clone https://github.com/zplug/zplug $ZPLUG_HOME

echo install zshrc etc
rsync -av --progress ../.* $HOME/ --exclude .git --exclude .gitmodules

echo install vim plugins
vim +PlugClean +qall
vim +PlugInstall +qall

echo install done
echo switch to zsh with: chsh -s /path/to/zsh
