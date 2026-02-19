eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

fpath+=("$(brew --prefix)/share/zsh/site-functions")

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

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

# fzf
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
  local branch=$(command claude -p "以下のタスクに適切なgitブランチ名を1つだけ出力して。命名規則: feature/xxx, fix/xxx, docs/xxx。英語ケバブケース。ブランチ名のみ出力。タスク: $task" | tr -d '`')

  if [ -z "$branch" ]; then
    echo "ブランチ名の決定に失敗しました"
    return 1
  fi

  echo "ブランチ: $branch"
  wt switch --create "$branch" --execute=claude -- "$task"
}

# cwtsend: テキストを送信（既定は右ペイン。--new-tab で新規タブ）
function cwtsend() {
  local mode="right"
  if [ "$1" = "--new-tab" ]; then
    mode="new-tab"
    shift
  fi

  local text="$*"
  if [ -z "$text" ]; then
    echo "Usage: cwtsend [--new-tab] <送信するテキスト>"
    return 1
  fi

  if [ -z "${WEZTERM_PANE:-}" ]; then
    echo "WezTermのペイン内で実行してください"
    return 1
  fi

  if ! command -v wezterm >/dev/null 2>&1; then
    echo "wezterm コマンドが見つかりません"
    return 1
  fi

  local target
  if [ "$mode" = "new-tab" ]; then
    target=$(wezterm cli spawn --cwd "$PWD" 2>/dev/null | tr -d '[:space:]')
  else
    target=$(wezterm cli get-pane-direction Right 2>/dev/null | tr -d '[:space:]')
    if [ -z "$target" ]; then
      target=$(wezterm cli split-pane --right --percent 50 --cwd "$PWD" 2>/dev/null | tr -d '[:space:]')
    fi
  fi

  if [ -z "$target" ]; then
    echo "送信先ペインの準備に失敗しました"
    return 1
  fi

  printf '%s\n' "$text" | wezterm cli send-text --pane-id "$target" --no-paste
}

# cwtstart: 議論セッションを維持したまま、右ペインで実装セッションを開始
function cwtstart() {
  local task="$*"
  if [ -z "$task" ]; then
    echo "Usage: cwtstart <タスクの説明>"
    return 1
  fi

  cwtsend "cwt $task"$'\n'
}
