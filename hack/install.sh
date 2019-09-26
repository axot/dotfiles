#!/bin/bash

set -ex

echo install zim first
git clone --recursive https://github.com/zimfw/zimfw.git ${ZDOTDIR:-${HOME}}/.zim
for template_file in ${ZDOTDIR:-${HOME}}/.zim/templates/*; do
  user_file="${ZDOTDIR:-${HOME}}/.${template_file:t}"
  cat ${template_file} ${user_file}(.N) > ${user_file}.tmp && mv ${user_file}{.tmp,}
done
source ${ZDOTDIR:-${HOME}}/.zlogin

echo install zplug
mkdir -p /usr/local/opt/zplug
export ZPLUG_HOME=/usr/local/opt/zplug
git clone https://github.com/zplug/zplug $ZPLUG_HOME

echo install zshrc etc
cp -r ../* ../.* $HOME/

echo switch to zsh with `chsh -s /path/to/zsh`

echo install vim plugins
nvim +PlugInstall +qall

echo install done
