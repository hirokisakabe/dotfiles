#!/usr/bin/env bash

set -euo pipefail

: "${AGENT_SKILLS_DIR:?AGENT_SKILLS_DIR is required}"
: "${CLAUDE_SKILLS_DIR:?CLAUDE_SKILLS_DIR is required}"
: "${CODEX_SKILLS_DIR:?CODEX_SKILLS_DIR is required}"

is_managed_skill() {
  local skill_file_path expected_repository expected_skill_path
  skill_file_path="$1/SKILL.md"
  expected_repository="https://github.com/$2"
  expected_skill_path="skills/$3"
  [ -f "$skill_file_path" ] || return 1
  awk -v expected_repository="$expected_repository" -v expected_skill_path="$expected_skill_path" '
    NR == 1 { if ($0 != "---") exit 1; frontmatter = 1; next }
    frontmatter && $0 == "---" {
      closed = 1
      valid_sha = length(tree_sha) == 40 && tree_sha !~ /[^0-9a-f]/
      exit !(metadata_count == 1 && !invalid_metadata && repo_count == 1 && path_count == 1 && sha_count == 1 && repository == expected_repository && skill_path == expected_skill_path && valid_sha)
    }
    frontmatter && $0 == "metadata:" { metadata = 1; metadata_count++; next }
    metadata && /^[^[:space:]]/ { metadata = 0 }
    metadata && /^  [^ ]/ { invalid_metadata = 1; metadata = 0 }
    metadata && /^    github-repo:[[:space:]]*/ { repo_count++; repository = $0; sub(/^    github-repo:[[:space:]]*/, "", repository); next }
    metadata && /^    github-path:[[:space:]]*/ { path_count++; skill_path = $0; sub(/^    github-path:[[:space:]]*/, "", skill_path); next }
    metadata && /^    github-tree-sha:[[:space:]]*/ { sha_count++; tree_sha = $0; sub(/^    github-tree-sha:[[:space:]]*/, "", tree_sha); next }
    END { if (!closed) exit 1 }
  ' "$skill_file_path" >/dev/null
}

mkdir -p "$AGENT_SKILLS_DIR" "$CLAUDE_SKILLS_DIR"

for skill_spec in "$@"; do
  repository=${skill_spec%:*}
  skill=${skill_spec#*:}
  canonical_path="$AGENT_SKILLS_DIR/$skill"
  claude_path="$CLAUDE_SKILLS_DIR/$skill"
  codex_path="$CODEX_SKILLS_DIR/$skill"

  if [ -L "$canonical_path" ]; then
    if is_managed_skill "$canonical_path" "$repository" "$skill"; then
      rm -f "$canonical_path"
    else
      printf '%s\n' "管理外の symlink と競合しています: $canonical_path" >&2
      exit 1
    fi
  elif [ -e "$canonical_path" ] && ! is_managed_skill "$canonical_path" "$repository" "$skill"; then
    printf '%s\n' "管理外の既存 skill と競合しています: $canonical_path" >&2
    exit 1
  fi

  gh skill install "$repository" "$skill" --dir "$AGENT_SKILLS_DIR" -f

  if [ -L "$claude_path" ]; then
    target=$(readlink "$claude_path")
    if [ "$claude_path" -ef "$canonical_path" ]; then
      :
    elif [ ! -e "$claude_path" ]; then
      printf '%s\n' "既存の壊れた外部 symlink を保持します: $claude_path -> $target"
    elif is_managed_skill "$claude_path" "$repository" "$skill"; then
      rm -f "$claude_path"
    else
      printf '%s\n' "既存の外部 symlink を保持します: $claude_path -> $target"
    fi
  elif [ -e "$claude_path" ]; then
    if is_managed_skill "$claude_path" "$repository" "$skill"; then
      rm -rf "$claude_path"
    else
      printf '%s\n' "管理外の既存 skill を保持します: $claude_path"
    fi
  fi

  if [ ! -e "$claude_path" ] && [ ! -L "$claude_path" ]; then
    if [ "$AGENT_SKILLS_DIR" = "$HOME/.agents/skills" ] && [ "$CLAUDE_SKILLS_DIR" = "$HOME/.claude/skills" ]; then
      link_target="../../.agents/skills/$skill"
    else
      link_target="$canonical_path"
    fi
    ln -s "$link_target" "$claude_path"
  fi

  if [ -L "$codex_path" ]; then
    target=$(readlink "$codex_path")
    if [ -e "$codex_path" ] && { [ "$codex_path" -ef "$canonical_path" ] || is_managed_skill "$codex_path" "$repository" "$skill"; }; then
      rm -f "$codex_path"
    else
      printf '%s\n' "既存の外部 symlink を保持します: $codex_path -> $target"
    fi
  elif [ -e "$codex_path" ]; then
    if is_managed_skill "$codex_path" "$repository" "$skill"; then
      rm -rf "$codex_path"
    else
      printf '%s\n' "管理外の既存 skill を保持します: $codex_path"
    fi
  fi
done
