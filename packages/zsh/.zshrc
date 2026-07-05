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
alias wsc='wt switch --create --execute=claude'
alias gwr='cd $(git worktree list | head -1 | awk "{print \$1}")'

# cwt: coding worktree - AI にブランチ名を決めさせて worktree で agent を起動
function cwt() {
  local agent="codex"
  local -a task_parts

  while [ $# -gt 0 ]; do
    case "$1" in
      --codex)
        agent="codex"
        shift
        ;;
      --claude)
        agent="claude"
        shift
        ;;
      -h | --help)
        echo "Usage: cwt [--codex|--claude] <issue-url|issue-number|task text>"
        return 0
        ;;
      --)
        shift
        task_parts+=("$@")
        break
        ;;
      --*)
        echo "unknown option: $1"
        return 1
        ;;
      *)
        task_parts+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#task_parts[@]} -eq 0 ]; then
    echo "Usage: cwt [--codex|--claude] <issue-url|issue-number|task text>"
    return 1
  fi

  if ! command -v "$agent" >/dev/null 2>&1; then
    echo "$agent command not found"
    return 1
  fi
  if ! command -v wt >/dev/null 2>&1; then
    echo "wt command not found"
    return 1
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "not inside a git repository"
    return 1
  }
  repo_root="${repo_root:A}"

  local primary_worktree
  primary_worktree=$(git -C "$repo_root" worktree list --porcelain | sed -n '1s/^worktree //p')
  primary_worktree="${primary_worktree:A}"
  if [ "$repo_root" != "$primary_worktree" ]; then
    echo "cwt must be run from the primary worktree"
    echo "current: $repo_root"
    echo "primary: $primary_worktree"
    return 1
  fi

  local task issue_ref issue_context agent_prompt
  task="${(j: :)task_parts}"
  issue_context=""

  if [[ "$task" == <-> ]]; then
    issue_ref="$task"
  elif [[ "$task" == \#<-> ]]; then
    issue_ref="${task#\#}"
  elif [[ "$task" =~ '^https://github.com/([^/]+)/([^/]+)/issues/([0-9]+)([/?#].*)?$' ]]; then
    if ! command -v gh >/dev/null 2>&1; then
      echo "gh command not found"
      return 1
    fi
    local issue_repo current_repo
    issue_repo="${match[1]}/${match[2]}"
    current_repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    if [ -n "$current_repo" ] && [ "$issue_repo" != "$current_repo" ]; then
      echo "issue belongs to another repository: $issue_repo"
      echo "current repository: $current_repo"
      return 1
    fi
    issue_ref="$task"
  fi

  if [ -n "$issue_ref" ]; then
    if ! command -v gh >/dev/null 2>&1; then
      echo "gh command not found"
      return 1
    fi
    issue_context=$(gh issue view "$issue_ref" --json title,body,url --template '{{printf "URL: %s\nTitle: %s\nBody:\n%s\n" .url .title .body}}') || return 1
    agent_prompt="Work on this issue:

$issue_context"
  else
    agent_prompt="$task"
  fi

  local naming_source naming_prompt branch
  naming_source="${issue_context:-$task}"
  naming_prompt="Generate exactly one git branch name for this task.

Rules:
- Output only the branch name.
- Use one of these prefixes: feat/, fix/, chore/, docs/, refactor/.
- Use concise English kebab-case after the prefix.
- Prefer 3 to 6 words after the prefix.
- Do not wrap the answer in quotes or backticks.

Task:
$naming_source"

  echo "ブランチ名を決定中..."
  if command -v codex >/dev/null 2>&1; then
    local branch_file
    local -a codex_namer_args
    branch_file=$(mktemp "${TMPDIR:-/tmp}/cwt-branch.XXXXXX") || return 1
    codex_namer_args=(exec --ephemeral --sandbox read-only --skip-git-repo-check --ignore-rules)
    if [ -n "$CWT_NAMER_MODEL" ]; then
      codex_namer_args+=(-m "$CWT_NAMER_MODEL")
    fi
    command codex "${codex_namer_args[@]}" -o "$branch_file" "$naming_prompt" >/dev/null || {
      rm -f "$branch_file"
      return 1
    }
    branch=$(tail -n 1 "$branch_file" | tr -d '`' | xargs)
    rm -f "$branch_file"
  elif command -v claude >/dev/null 2>&1; then
    branch=$(command claude -p "$naming_prompt" | tail -n 1 | tr -d '`' | xargs)
  else
    echo "codex or claude command not found"
    return 1
  fi

  if [ -z "$branch" ]; then
    echo "ブランチ名の決定に失敗しました"
    return 1
  fi

  branch="${branch#refs/heads/}"
  if [[ ! "$branch" =~ '^(feat|fix|chore|docs|refactor)/[a-z0-9]+(-[a-z0-9]+)*$' ]]; then
    echo "invalid branch name format: $branch"
    echo "expected: feat|fix|chore|docs|refactor followed by english kebab-case"
    return 1
  fi
  if ! git -C "$repo_root" check-ref-format --branch "$branch" >/dev/null 2>&1; then
    echo "invalid branch name: $branch"
    return 1
  fi
  if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "branch already exists: $branch"
    return 1
  fi

  echo "branch: $branch"
  local prompt_file launcher_file
  prompt_file=$(mktemp "${TMPDIR:-/tmp}/cwt-prompt.XXXXXX") || return 1
  launcher_file=$(mktemp "${TMPDIR:-/tmp}/cwt-launcher.XXXXXX") || {
    rm -f "$prompt_file"
    return 1
  }
  print -r -- "$agent_prompt" >"$prompt_file" || {
    rm -f "$prompt_file" "$launcher_file"
    return 1
  }
  cat >"$launcher_file" <<'EOF'
#!/bin/sh
set -eu
agent=$1
prompt_file=$2
prompt=$(cat "$prompt_file")
rm -f "$prompt_file" "$0"
exec "$agent" "$prompt"
EOF
  chmod +x "$launcher_file" || {
    rm -f "$prompt_file" "$launcher_file"
    return 1
  }

  command wt switch --create "$branch" --base=@ --execute="$launcher_file" -- "$agent" "$prompt_file"
  local cwt_status=$?
  if [ "$cwt_status" -ne 0 ]; then
    rm -f "$prompt_file" "$launcher_file"
  fi
  return "$cwt_status"
}

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

# git-wt (git worktree helper)
eval "$(git wt --init zsh)"

# worktrunk (git worktree manager)
eval "$(wt config shell init zsh)"

# atuin
eval "$(atuin init zsh)"
