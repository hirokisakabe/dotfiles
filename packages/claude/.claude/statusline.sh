#!/bin/bash
# Claude Code statusLine: model, branch, tokens, 5h rate limit
input=$(cat)
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || echo "?")
echo "$input" | jq -r --arg b "$BRANCH" '
  "[\(.model.display_name)] (\($b)) " +
  "\(.context_window.total_input_tokens // 0) IN / \(.context_window.total_output_tokens // 0) OUT (\(.context_window.used_percentage // 0)%) " +
  "| 5h: \(.rate_limits.five_hour.used_percentage // 0)% (resets \(.rate_limits.five_hour.resets_at // 0 | if . > 0 then strflocaltime("%H:%M") else "?" end))"
'
