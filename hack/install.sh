#!/usr/bin/env zsh

echo install zim first
git clone --recursive https://github.com/zimfw/zimfw.git ${ZDOTDIR:-${HOME}}/.zim
for template_file in ${ZDOTDIR:-${HOME}}/.zim/templates/*; do
  user_file="${ZDOTDIR:-${HOME}}/.${template_file:t}"
  cat ${template_file} ${user_file}(.N) > ${user_file}.tmp && mv ${user_file}{.tmp,}
done
source ${ZDOTDIR:-${HOME}}/.zlogin

echo install zplug
export ZPLUG_HOME=$HOME/zplug
mkdir -p $ZPLUG_HOME
git clone https://github.com/zplug/zplug $ZPLUG_HOME

echo install zshrc etc
rsync -av --progress ../ $HOME/ --exclude .git --exclude .gitmodules

echo install vim plugins
vim +PlugInstall +qall

echo install done
echo switch to zsh with: chsh -s /path/to/zsh
