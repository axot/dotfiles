# axot zsh config file - common

VER="140327"
DOTZSHDIR="$HOME/.zshrc.d"

function loadsubconf()
{
    [[ -s $DOTZSHDIR/$1 ]] && {echo Loading $1 ...; . $DOTZSHDIR/$1}
}

echo Loading zsh ...

loadsubconf zshrc.const

# Common Settings

# VI keymap
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^F' forward-char
bindkey '^B' backward-char
bindkey '^K' kill-line
bindkey '^P' up-history
bindkey '^N' down-history

## Alias
alias reload='source ~/.zshrc'
alias ipython='ipython --pylab'

## Extension Alias
alias -s tgz='tar -zxvf'


## Z Shell Configs
autoload -U compinit  
compinit 

zstyle ':completion:*:default' menu select true

autoload -U promptinit  
promptinit  
prompt adam2 cyan green magenta
zmodload -i zsh/mathfunc

HISTFILE=$DOTZSHDIR/zhistory
HISTSIZE=10000
SAVEHIST=20000

### We set some options here
setopt autocd
setopt hist_reduce_blanks hist_ignore_all_dups share_history appendhistory
setopt correct
setopt auto_pushd
setopt list_packed
setopt complete_in_word auto_list auto_menu menu_complete
setopt multios
setopt extended_glob
setopt always_to_end
setopt bash_auto_list

case ${OSTYPE} in
    darwin*)
        loadsubconf zshrc.osx
        ;;
    *bsd*)
        loadsubconf zshrc.bsd
        ;;
    linux*)
        loadsubconf zshrc.nix
        ;;
esac

loadsubconf zshrc.private
loadsubconf zshrc.local

# Common Exporting
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export PAGER=less
export EDITOR=vim
#export LIBRARY_PATH=$OPT/local/lib:/usr/lib:$LIBRARY_PATH
#export C_INCLUDE_PATH=$OPT/local/include:/usr/include:$C_INCLUDE_PATH
#export CPLUS_INCLUDE_PATH=$OPT/local/include:/usr/include:$CPLUS_INCLUDE_PATH

# load RVM function
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm

echo ZSH config $VER was loaded, enjoy it.

