#!/bin/bash
LOG="/tmp/update_brew.log"

exec 1<&-
exec 2<&-
exec 1<>"$LOG"

echo Update homebrew
brew update 2>&1
echo %

echo Upgrade pkgs
brew upgrade 2>&1
echo %

PASS=`security find-generic-password -a ${USER} -s brew_cu -w`
sudo -S -v <<< $PASS

echo Update Cask
brew cu -fay 2>&1
echo %

echo Clean up
brew cleanup -s >/dev/null 2>&1
brew cask cleanup >/dev/null 2>&1
rm -rf $(brew --cache)/*.tar.gz >/dev/null 2>&1
rm -rf $(brew --cache)/Cask/*.dmg >/dev/null 2>&1

cat "$LOG" | mail -s 'RE: PKGs Update Report' axot@msn.com
rm "$LOG"
