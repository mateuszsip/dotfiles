#!/usr/bin/env bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')

# Build truncated directory
parts=$(echo "$cwd" | tr '/' '\n' | grep -v '^$')
count=$(echo "$parts" | wc -l)
if [ "$count" -le 2 ]; then
  display_dir=$(echo "$cwd" | sed 's|^/home/[^/]*|~|')
else
  display_dir="…/$(echo "$parts" | tail -n 2 | tr '\n' '/' | sed 's|/$||')"
fi

# Git info
git_branch=""
git_status_str=""
git_status_vis=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  [ -z "$git_branch" ] && git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

  ahead=$(git -C "$cwd" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  behind=$(git -C "$cwd" --no-optional-locks rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    git_status_vis="⇕⇡${ahead}⇣${behind} "; git_status_str="$git_status_vis"
  elif [ "$ahead" -gt 0 ]; then
    git_status_vis="⇡${ahead} "; git_status_str="$git_status_vis"
  elif [ "$behind" -gt 0 ]; then
    git_status_vis="⇣${behind} "; git_status_str="$git_status_vis"
  fi
  [ "$untracked" -gt 0 ] && git_status_vis="${git_status_vis}? " && git_status_str="${git_status_str}? "
  [ "$modified" -gt 0 ]  && git_status_vis="${git_status_vis}~ " && git_status_str="${git_status_str} "
  [ "$staged" -gt 0 ]    && git_status_vis="${git_status_vis}+ " && git_status_str="${git_status_str} "
fi

# Token / context usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

fmt_tokens() {
  local n_int
  n_int=$(printf "%.0f" "$1" 2>/dev/null) || n_int=0
  if [ "$n_int" -ge 1000 ]; then
    printf "%.1fk" "$(awk "BEGIN{printf \"%.1f\", $n_int/1000}")"
  else
    echo "$n_int"
  fi
}

ctx_vis=""
if [ -n "$used_pct" ]; then
  used_pct_int=$(printf "%.0f" "$used_pct")
  in_fmt=$(fmt_tokens "$total_in")
  out_fmt=$(fmt_tokens "$total_out")
  ctx_vis="${used_pct_int}%  ↑${in_fmt}  ↓${out_fmt}"
fi

# Colors
CYAN='\033[0;36m'
ITALIC_CYAN='\033[3;36m'
AMBER='\033[1;33m'
GRAY='\033[38;5;245m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# PR number
pr_number=$(gh -C "$cwd" pr view --json number -q '.number' 2>/dev/null)

# Effort (colored text + visible text for length tracking)
effort_col=""
effort_vis=""
if [ -n "$effort" ]; then
  case "$effort" in
    high)   effort_col="$(printf "${RED}high${RESET}")";   effort_vis="high" ;;
    medium) effort_col="$(printf "${YELLOW}med${RESET}")"; effort_vis="med"  ;;
    low)    effort_col="$(printf "${GREEN}low${RESET}")";  effort_vis="low"  ;;
    *)      effort_col="$(printf "${GRAY}${effort}${RESET}")"; effort_vis="$effort" ;;
  esac
fi

# Cost
cost_col=""
cost_vis=""
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  cost_vis="$(printf '$%.2f' "$cost_usd")"
  cost_col="$(printf "${AMBER}%s${RESET}" "$cost_vis")"
fi

# --- Line 1: session name ---
line1_col=""
[ -n "$session_name" ] && line1_col="$(printf "${GRAY}%s${RESET}" "$session_name")"

# --- Line 2: dir (left) | branch pr git (right) ---
line2_left_col="$(printf "${CYAN}%s${RESET}" "$display_dir")"
line2_left_vis="$display_dir"

line2_col="${line2_left_col}"
append2() { [ -n "$2" ] && line2_col="${line2_col}  $1"; }
append2 "$(printf "${ITALIC_CYAN}%s${RESET}" "$git_branch")"     "$git_branch"
append2 "$(printf "${GRAY}#%s${RESET}"       "$pr_number")"      "$pr_number"
append2 "$(printf "${CYAN}%s${RESET}"        "$git_status_str")" "$git_status_vis"

# --- Line 3: model  effort  ctx  cost
line3_col=""
append3() { [ -n "$line3_col" ] && line3_col="${line3_col}  "; line3_col="${line3_col}$1"; }
[ -n "$model_name" ] && append3 "$(printf "${GRAY}%s${RESET}" "$model_name")"
[ -n "$effort_col" ] && append3 "$effort_col"
[ -n "$ctx_vis" ]    && append3 "$(printf "${AMBER}%s${RESET}" "$ctx_vis")"
[ -n "$cost_col" ]   && append3 "$cost_col"

[ -n "$line1_col" ] && printf "%b\n" "$line1_col"
printf "%b\n" "$line2_col"
[ -n "$line3_col" ] && printf "%b" "$line3_col"
