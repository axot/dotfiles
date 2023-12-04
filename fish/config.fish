# Fish configuration

# Set version and directory variables
set VER "20231201"
echo "Loading fish ..."

# Function ns
function ns
    kubectl config set-context --current --namespace=(kubectl get ns --no-headers -o custom-columns=":metadata.name" | fzf)
end

# Aliases
alias reload="source ~/.config/fish/config.fish"
alias ns=ns
alias c=kubectx
alias k=tubectl

alias kd="kubectl describe"
alias kg="kubectl get"
alias kgp="kubectl get pod"
alias ke="kubectl edit"
alias keti="kubectl exec -ti"

for i in (seq 1 9)
    alias $i="awk '{print \$$i}'"
end

# Common Exports
set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8
set -x LC_CTYPE en_US.UTF-8
set -x PAGER less
set -x EDITOR vim
set -x XDG_CONFIG_HOME $HOME/.config

# RVM function loading
if test -s $HOME/.rvm/scripts/rvm
    source $HOME/.rvm/scripts/rvm
end
set -x PATH /opt/homebrew/bin $HOME/.rvm/bin $PATH

# Load fish completions for kubectl
kubectl completion fish | source

# Check if ~/.config.local.fish exists and source it
if test -f ~/.config.local.fish
    echo "Loading local.fish ..."
    source ~/.config.local.fish
end
