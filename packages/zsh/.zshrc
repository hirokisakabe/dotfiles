eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export PATH="$HOME/.local/bin:$PATH"

fpath+=("/opt/homebrew/share/zsh/site-functions")

function set_win_title() {
    echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

# OSC 7: ディレクトリ変更時にターミナルへ通知（WezTermの新しいタブ/ペインでcwdを引き継ぐため）
function notify_cwd() {
    printf '\e]7;file://%s%s\e\\' "${HOST}" "${PWD}"
}
chpwd_functions+=(notify_cwd)

autoload -U compinit
compinit

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt share_history
setopt hist_ignore_all_dups
setopt auto_cd

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# alias
alias cd..="cd .."
alias cdr="cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias c='clear'
alias h='history'
alias cl='claude'
alias cx='codex'
alias ports='lsof -i -P -n | grep LISTEN'
alias gwr='cd $(git worktree list | head -1 | awk "{print \$1}")'

# starship
eval "$(starship init zsh)"

# Frosted Aqua color palette
# eza
export EZA_COLORS="di=1;38;2;76;135;199:ln=38;2;55;138;155:ex=38;2;63;137;105:fi=38;2;32;59;82:*.md=38;2;128;118;179:*.json=38;2;150;104;36:*.lock=38;2;109;132;150:*.toml=38;2;150;104;36:*.yml=38;2;150;104;36:*.yaml=38;2;150;104;36"

# fzf
export FZF_DEFAULT_OPTS="
  --border=rounded --preview-border=rounded --margin=1 --padding=1,2
  --color=fg:#203b52,bg:#ddf4fa,hl:#4c87c7
  --color=fg+:#12283a,bg+:#c7eaf6,hl+:#5e9bd9
  --color=info:#3f8969,prompt:#8076b3,pointer:#b84f68
  --color=marker:#966824,spinner:#378a9b,header:#4c87c7
  --color=border:#8abdd0"
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"

# Terraform
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C terraform terraform

# mise
eval "$(/opt/homebrew/bin/mise activate zsh)"

# npm: publish 直後の悪意あるバージョン取り込みを避けるため、7日経過したバージョンのみ install 対象とする
# 要 npm >= 11.10.0
export NPM_CONFIG_MIN_RELEASE_AGE=7

# git-wt (git worktree helper)
eval "$(git wt --init zsh)"

# atuin
eval "$(atuin init zsh)"
