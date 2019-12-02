#!/bin/bash
LOG="/tmp/update_brew.log"

exec 1<&-
exec 2<&-
exec 1<>"$LOG"

echo Update homebrew
/usr/local/bin/brew update 2>&1
echo %

echo Upgrade pkgs
/usr/local/bin/brew upgrade 2>&1
echo %

PASS=`security find-generic-password -a ${USER} -s brew_cu -w`
sudo -S -v <<< $PASS

echo Update Cask
/usr/local/bin/brew cu -fay 2>&1
echo %

echo Clean up
/usr/local/bin/brew cleanup -s >/dev/null 2>&1
/usr/local/bin/brew cask cleanup >/dev/null 2>&1
rm -rf $(/usr/local/bin/brew --cache)/*.tar.gz >/dev/null 2>&1
rm -rf $(/usr/local/bin/brew --cache)/Cask/*.dmg >/dev/null 2>&1

cat "$LOG" | mail -s 'RE: PKGs Update Report' axot@msn.com
rm "$LOG"
