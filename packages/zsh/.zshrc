eval "$(/opt/homebrew/bin/brew shellenv)"
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
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# alias
alias cd..="cd .."
alias cdr="cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias c='clear'
alias h='history'
alias cl='claude'
alias ports='lsof -i -P -n | grep LISTEN'
alias wsc='wt switch --create --execute=claude'
alias gwr='cd $(git worktree list | head -1 | awk "{print \$1}")'

# direnv
eval "$(direnv hook zsh)"

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

# Terraform
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# mise
eval "$(/opt/homebrew/bin/mise activate zsh)"

# git-wt (git worktree helper)
eval "$(git wt --init zsh)"

# worktrunk (git worktree manager)
eval "$(wt config shell init zsh)"

# claude: mainブランチではコード変更を行わないセッションとして起動
function claude() {
  local branch=$(git branch --show-current 2>/dev/null)
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    command claude --append-system-prompt \
      "現在mainブランチにいます。このセッションではコードの変更やgit操作（checkout, commit, branch作成等）を行わないでください。issue起票、アーキテクチャ議論、調査、レビューなど、コード変更を伴わないタスクのみ対応してください。実装が必要な場合はissueを作成するか、ユーザーにcwtコマンドの使用を提案してください。" \
      "$@"
  else
    command claude "$@"
  fi
}

# cwt: claude worktree - タスクからブランチ名を決定しworktreeを作成して対話開始
function cwt() {
  local task="$*"
  if [ -z "$task" ]; then
    echo "Usage: cwt <タスクの説明>"
    return 1
  fi

  echo "ブランチ名を決定中..."
  local branch=$(command claude -p "以下のタスクに適切なgitブランチ名を1つだけ出力して。命名規則: feature/xxx, fix/xxx, docs/xxx。英語ケバブケース。ブランチ名のみ出力。タスク: $task" | tr -d '`' | xargs)

  if [ -z "$branch" ]; then
    echo "ブランチ名の決定に失敗しました"
    return 1
  fi

  echo "ブランチ: $branch"
  wt switch --create "$branch" --execute=claude -- "$task"
}
