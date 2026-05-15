#!/usr/bin/env bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')

# Build truncated directory (truncation_length = 2, truncation_symbol = "…/")
# Show last 2 path components, prefixed with "…/" if truncated
parts=$(echo "$cwd" | tr '/' '\n' | grep -v '^$')
count=$(echo "$parts" | wc -l)
if [ "$count" -le 2 ]; then
  display_dir=$(echo "$cwd" | sed 's|^/home/[^/]*|~|')
else
  display_dir="…/$(echo "$parts" | tail -n 2 | tr '\n' '/' | sed 's|/$||')"
fi

# Git info (using --no-optional-locks to avoid lock contention)
git_branch=""
git_status_str=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -z "$git_branch" ]; then
    git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi

  # Gather status indicators
  ahead=$(git -C "$cwd" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  behind=$(git -C "$cwd" --no-optional-locks rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    git_status_str="⇕⇡${ahead}⇣${behind} "
  elif [ "$ahead" -gt 0 ]; then
    git_status_str="⇡${ahead} "
  elif [ "$behind" -gt 0 ]; then
    git_status_str="⇣${behind} "
  fi
  [ "$untracked" -gt 0 ] && git_status_str="${git_status_str}? "
  [ "$modified" -gt 0 ]  && git_status_str="${git_status_str} "
  [ "$staged" -gt 0 ]    && git_status_str="${git_status_str} "
fi

# Token / context usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# Format token counts with k suffix
fmt_tokens() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" -eq 0 ] 2>/dev/null; then
    echo "0"
  elif [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    echo "$n"
  fi
}

ctx_str=""
if [ -n "$used_pct" ]; then
  used_pct_int=$(printf "%.0f" "$used_pct")
  remaining_pct=$((100 - used_pct_int))
  in_fmt=$(fmt_tokens "$total_in")
  out_fmt=$(fmt_tokens "$total_out")
  ctx_str="${used_pct_int}% ctx | in:${in_fmt} out:${out_fmt}"
fi

# Compose output with ANSI colors (cyan to match Starship theme)
CYAN='\033[0;36m'
ITALIC_CYAN='\033[3;36m'
DIM_YELLOW='\033[2;33m'
DIM='\033[2m'
RESET='\033[0m'

output=""
output="${output}$(printf "${CYAN}%s${RESET}" "$display_dir")"
if [ -n "$git_branch" ]; then
  output="${output} $(printf "${ITALIC_CYAN}%s${RESET}" "$git_branch")"
fi
if [ -n "$git_status_str" ]; then
  output="${output} $(printf "${CYAN}%s${RESET}" "$git_status_str")"
fi
if [ -n "$ctx_str" ]; then
  output="${output} $(printf "${DIM_YELLOW}%s${RESET}" "$ctx_str")"
fi

printf "%b" "$output"
