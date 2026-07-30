# Dotfiles — Chezmoi Management

This repo (`~/.local/share/chezmoi/`) is the **source** for chezmoi-managed
dotfiles. Files here deploy to `$HOME` via `chezmoi apply`.

## Path mapping

| Chezmoi source                          | Deployed path             |
| --------------------------------------- | ------------------------- |
| `dot_config/<dir>/<file>`               | `~/.config/<dir>/<file>`  |
| `dot_<file>`                            | `~/.<file>`               |

### Naming conventions
- `dot_` prefix     → leading `.` in the deployed path
- `private_` prefix  → file deployed with mode `600`
- `.tmpl` suffix     → Go template, rendered on apply (access `.chezmoi.os`, `.chezmoi.arch`, user data from `.chezmoi.toml.tmpl`)
- `run_once_` prefix → script runs once per machine on `chezmoi apply`
- `run_onchange_` prefix → script runs when the file content changes
- `executable_` prefix → file deployed with the executable bit set

## OS-specific files

`.chezmoiignore.tmpl` excludes platform-inappropriate files:
- **Linux**: omarchy, waybar, hypr, nvim theme hot-reload are tracked
- **macOS**: aerospace, mac-themed nvim plugins are tracked

Within Linux, Mac-hardware-specific config (Apple Silicon keyboard layout,
macsmc-battery, keyboard backlight bindings) is gated on
`{{- if eq .chezmoi.osRelease.id "archarm" }}` (Asahi Linux on Apple Silicon).
Files using this pattern: `dot_config/hypr/input.conf.tmpl`,
`dot_config/hypr/bindings.conf.tmpl`, `dot_config/waybar/config.jsonc.tmpl`.

Use Go template conditionals in `.tmpl` files for per-OS config. Example from
`dot_config/opencode/opencode.json.tmpl`:

```
{{- if eq .chezmoi.os "darwin" }}
    "@mohak34/opencode-notifier@latest",
{{- else if eq .chezmoi.os "linux" }}
    "./waybar-notify.ts",
{{- end }}
```

Available template data: `.chezmoi.os` (`linux`/`darwin`), `.chezmoi.arch`,
and custom data from `.chezmoi.toml.tmpl` under `.[data]` (`email`,
`bitwarden_agent`, `git_gpgsign`, `homebrew_user_appdir`).

## Workflow

### Editing config — two equivalent approaches

**A) Edit deployed, sync back (preferred for existing files):**
```bash
# edit the live file at its deployed location
$EDITOR ~/.config/<dir>/<file>
# pull the change into chezmoi source
chezmoi add ~/.config/<dir>/<file>
```

**B) Edit chezmoi source directly (preferred for templates & new files):**
```bash
# edit the source file
$EDITOR ~/.local/share/chezmoi/dot_config/<dir>/<file>
# preview the diff before applying
chezmoi diff
# deploy to $HOME
chezmoi apply
```

### Committing

After `chezmoi add` or direct source edits:
```bash
git -C ~/.local/share/chezmoi add -A
git -C ~/.local/share/chezmoi commit -m "message"
```

## Critical rules for AI agents

0. **NEVER override existing live changes.** Before `chezmoi apply` (even with
   permission) run `chezmoi diff` and check for un-synced local edits. If the
   deployed file has changes the source doesn't, the user has unsaved work —
   offer `chezmoi add` to absorb it first, or stop and ask. Never `apply` over
   a file whose live content differs from source in a way the user hasn't
   confirmed.

1. **Never run `chezmoi apply` without explicit user permission.** It overwrites
   the user's live files. Prefer `chezmoi diff` to show what *would* change,
   and let the user decide.
2. **Never `chezmoi add` a file the user is still editing** — it snapshots the
   current content, which may be a half-finished edit.
3. **When the user edits live files and asks you to sync**, run
   `chezmoi add <path>` then `git add -A && git commit`. Do NOT `chezmoi apply`
   afterward unless asked — the user already has their changes deployed.
4. **For templated files (`.tmpl`)**, always edit the source in this repo, not
   the deployed rendered file — `chezmoi add` on a rendered file will strip the
   template and replace it with the literal output.
5. **Test templates** with `chezmoi cat <source-path>` or `chezmoi diff` to
   verify rendering before committing.
6. **Encryption**: `.age` files are encrypted with the key at
   `~/.config/chezmoi/key.txt`. Never commit the key. Never read or log
   decrypted secret contents.

---

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (60-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk go test             # Go test failures only (90%)
rtk jest                # Jest failures only (99.5%)
rtk vitest              # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk pytest              # Python test failures only (90%)
rtk rake test           # Ruby test failures only (90%)
rtk rspec               # RSpec test failures only (60%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%). Format flags (-c, -l, -L, -o, -Z) run raw.
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->
