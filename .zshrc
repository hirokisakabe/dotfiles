eval "$(/opt/homebrew/bin/brew shellenv)"

fpath+=("$(brew --prefix)/share/zsh/site-functions")

function set_win_title() {
    echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

autoload -U compinit
compinit

setopt share_history
setopt hist_ignore_all_dups
setopt auto_cd

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# alias
alias cd..="cd .."
alias c='clear'
alias h='history'
alias ls='gls --group-directories-first -1p --color=auto'

# direnv
eval "$(direnv hook zsh)"

# starship
eval "$(starship init zsh)"

# Terraform
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# kubectl
source <(kubectl completion zsh)
alias k=kubectl
compdef __start_kubectl k

# mise
eval "$(/opt/homebrew/bin/mise activate zsh)"
