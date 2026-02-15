eval "$(/opt/homebrew/bin/brew shellenv)"

fpath+=("$(brew --prefix)/share/zsh/site-functions")

function set_win_title() {
    echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

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

  local main_dir=$(pwd)
  echo "ブランチ: $branch"
  git wt "$branch" main --copy ".env*" || return 1

  # WezTermに現在のディレクトリを通知（新しいタブ/ペインで同じディレクトリを開くため）
  printf '\e]7;file://%s%s\e\\' "${HOST}" "${PWD}"

  # worktree の settings.local.json を main のものへのシンボリックリンクに置き換え
  if [ -f "$main_dir/.claude/settings.local.json" ]; then
    mkdir -p .claude
    rm -f .claude/settings.local.json
    ln -s "$main_dir/.claude/settings.local.json" .claude/settings.local.json
  fi

  command claude "$task"
}
