eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS="--require-sha"
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
alias ports='lsof -i -P -n | grep LISTEN'
alias wsc='wt switch --create --execute=claude'
alias gwr='cd $(git worktree list | head -1 | awk "{print \$1}")'

# starship
eval "$(starship init zsh)"

# Iceberg color palette - https://github.com/cocopon/iceberg.vim
# eza
export EZA_COLORS="di=1;38;2;132;160;198:ln=38;2;137;184;194:ex=38;2;180;190;130:fi=38;2;198;200;209:*.md=38;2;160;147;199:*.json=38;2;226;164;120:*.lock=38;2;107;112;137:*.toml=38;2;226;164;120:*.yml=38;2;226;164;120:*.yaml=38;2;226;164;120"

# fzf
export FZF_DEFAULT_OPTS="
  --color=fg:#c6c8d1,bg:#161821,hl:#84a0c6
  --color=fg+:#c6c8d1,bg+:#1e2132,hl+:#84a0c6
  --color=info:#b4be82,prompt:#a093c7,pointer:#e27878
  --color=marker:#e2a478,spinner:#89b8c2,header:#84a0c6
  --color=border:#6b7089"
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"

# Terraform
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# mise
eval "$(/opt/homebrew/bin/mise activate zsh)"

# npm: publish 直後の悪意あるバージョン取り込みを避けるため、7日経過したバージョンのみ install 対象とする
# 要 npm >= 11.10.0
export NPM_CONFIG_MIN_RELEASE_AGE=7

# socket.dev safe npm: npm/npx をラップしてサプライチェーン攻撃をインストール前に検知する
alias npm="socket-npm"
alias npx="socket-npx"
compdef _npm socket-npm

# git-wt (git worktree helper)
eval "$(git wt --init zsh)"

# worktrunk (git worktree manager)
eval "$(wt config shell init zsh)"

# atuin
eval "$(atuin init zsh)"
