# AGENTS.md — Chezmoi Dotfiles

This repo (`~/.local/share/chezmoi/`) is the **source** for chezmoi-managed
dotfiles. Files here deploy to `$HOME` via `chezmoi apply`.

> Scope: this file guides work **in this repo**. It is not deployed itself
> (see `.chezmoiignore.tmpl`). The global agent memory at
> `~/.claude/CLAUDE.md` (source: `dot_claude/CLAUDE.md`) is a separate file.

## Layout (source → target)

| Source | Deploys to | Notes |
| ------ | ---------- | ----- |
| `dot_config/<dir>/` | `~/.config/<dir>/` | most app config |
| `dot_claude/`, `dot_gemini/` | `~/.claude/`, `~/.gemini/` | agent CLIs |
| `dot_local/bin/`, `dot_local/share/` | `~/.local/bin/`, `~/.local/share/` | user binaries/data |
| `dot_ssh/` | `~/.ssh/` | |
| `dot_docker/` | `~/.docker/` | via `modify_` script, not overwrite |
| `dot_pi/` | `~/.pi/` | |
| `dot_<file>` | `~/.<file>` | e.g. `dot_aerospace.toml` |
| `nu_scripts/` | `~/nu_scripts/` | **intentionally deployed** — sourced by nushell (`aliases.nu`, `completions.nu`) |
| `run_*.sh[.tmpl]` | nowhere | executed by `chezmoi apply`, not deployed |
| `packages_*.txt` | nowhere | data read by the install script via `include` (see below) |
| `docs/` | nowhere | local scratch, gitignored |

## Chezmoi attributes in use here

| Prefix/suffix | Effect |
| ------------- | ------ |
| `dot_` | leading `.` in deployed path |
| `private_` | deployed with mode `600` (e.g. `dot_ssh/private_config.tmpl`, `dot_claude/private_settings.json.tmpl`, `dot_config/atuin/private_config.toml`) |
| `executable_` | deployed with `+x` (hypr/waybar helpers, `dot_local/bin/*`) |
| `symlink_` | deployed as symlink (`systemd/user/` mask) |
| `modify_` | script patches target instead of overwriting (`dot_docker/modify_config.json`) |
| `.tmpl` | Go template, rendered on apply (29 files) |
| `.age` | age-encrypted (work secrets + `key.txt.age` bootstrap) |
| `run_once_` / `run_onchange_` | scripts (see below) |

`exact_`, `empty_`, `create_` are **not** used — don't introduce them without asking.

### Scripts: `run_[once|onchange]_[before|after]_<name>`

Middle token is a phase (`install`, `setup`) for readability; `before_`/`after_`
control ordering (before < main < after):

- `before`: `decrypt-private-key`, `plmac-keyboard`, `setup-system`
- main `install`: `packages`, `bosto-recovery`, `muse-acp`, `ripwire`
- main `setup`: `kbd-backlight`, `low-power-tdp`
- `once_after`: `01-osx`, `antigravity`, `fonts`, `node-packages`, `bosto-touchpad`, `rapl-readable`, `voxtype`
- `onchange_after`: `ghostty-display-font`, `setup-user-services`

## Template data

Built-ins: `.chezmoi.os` (`linux`/`darwin`), `.chezmoi.arch`,
`.chezmoi.hostname`, `.chezmoi.osRelease.id`. Custom data from
`.chezmoi.toml.tmpl` under `.[data]`:

| Key | Meaning |
| --- | ------- |
| `email` | static (`mateusz.sip@gmail.com`) |
| `bitwarden_agent` | `promptBool`, default false |
| `work_machine` | `promptBool`, default false — gates `nushell/lendable.nu`, `nvim/lua/db/lendable` |
| `git_gpgsign` | `promptBool`, default true |
| `homebrew_user_appdir` | prompted on macOS only, `false` elsewhere |

Example (from `dot_config/opencode/opencode.json.tmpl`):

```
{{- if eq .chezmoi.os "darwin" }}
    "@mohak34/opencode-notifier@latest",
{{- else if eq .chezmoi.os "linux" }}
    "./plugins/waybar-notify",
{{- end }}
```

## OS-specific gating

`.chezmoiignore.tmpl` excludes platform-inappropriate files:

- **macOS**: `aerospace.toml` and `ghostty-display-font.swift` tracked; waybar,
  hypr (incl. theme/backgrounds), mako, swayosd,
  hyprland-preview-share-picker, uwsm, pacsea, `environment.d/`, `systemd/`,
  `.bashrc`/`.bash_profile` and `docker/config.json` excluded.
- **Linux**: `aerospace.toml` excluded.
- **Linux, Asahi only** (`osRelease.id == "archarm"`): Mac-hardware config inline via
  `{{- if eq .chezmoi.osRelease.id "archarm" }}` in
  `hypr/input.conf.tmpl`, `hypr/bindings.conf.tmpl`, `waybar/config.jsonc.tmpl`.
  `environment.d/` and `systemd/` deploy on every Linux host.
- **Non-work machines**: `lendable.nu`, `nvim/lua/db/lendable` excluded.

## Packages workflow

`packages_arch.txt`, `packages_arch_aur.txt`, `packages_macos.txt`,
`packages_macos_taps.txt` (+ `*_work*` on work Macs) are read with `include`
by `run_onchange_install-packages.sh.tmpl`. The script embeds a
`sha256sum` of each list in a comment, so editing a list re-triggers install
on next `chezmoi apply`. Just edit the `.txt` — no other step needed.

## Workflow

**A) Edit deployed, sync back (existing files):**
```bash
$EDITOR ~/.config/<dir>/<file>
chezmoi add ~/.config/<dir>/<file>
```

**B) Edit source directly (templates, scripts, new files):**
```bash
$EDITOR ~/.local/share/chezmoi/dot_config/<dir>/<file>
chezmoi diff        # preview what apply would change
chezmoi apply       # deploy (needs explicit user permission)
```

Inspect: `chezmoi status` (live drift), `chezmoi cat <source-path>`
(render a template), `chezmoi doctor` (health check).

Committing (after `chezmoi add` or source edits):
```bash
git -C ~/.local/share/chezmoi add -A
git -C ~/.local/share/chezmoi commit -m "[scope] message"
```

## Validation

Before committing script or template edits:

```bash
chezmoi execute-template < run_onchange_<name>.sh.tmpl | bash -n   # renders + parses
chezmoi diff ~/.config/<path>                                      # what apply would change
```

`chezmoi status` only reports files chezmoi **manages**. Residue left by tooling
this repo retired (e.g. `~/.config/environment.d/omarchy.conf`, the old shader
symlinks) is invisible to it — when retiring a tool, look for stray files
explicitly, not just drift.

## Migration conventions

Large removals land as phased commits: `[scope] phase N: ...`, with
`TEMP(scope): ... Remove in Phase N` markers in the files carrying the debt.
Delete the marker in the same commit as the final phase. Do not branch per
phase — a divergent phase branch leaves half the work unmerged.

## Critical rules for AI agents

0. **NEVER overwrite live changes.** Before `chezmoi apply` (even with
   permission) run `chezmoi diff`. If a deployed file has changes the source
   doesn't, the user has unsaved work — offer `chezmoi add` first, or stop.
1. **Never run `chezmoi apply` without explicit user permission.**
   Prefer `chezmoi diff` and let the user decide.
2. **Never `chezmoi add` a file the user is still editing.**
3. **Sync requests**: `chezmoi add <path>` then `git add -A && git commit`.
   Do NOT `apply` after — changes are already live.
4. **Templated files (`.tmpl`)**: edit source only. `chezmoi add` on a rendered
   file strips the template into literal output.
5. **Test templates** with `chezmoi cat` / `chezmoi diff` before committing.
6. **Secrets**: age key at `~/.config/chezmoi/key.txt`. Never commit the key.
   Never read or log decrypted secret contents.

## RTK

Prefix dev commands with `rtk` (`rtk git status`, `rtk cargo test`, …) for
60–90% token savings on output. Full reference: `rtk --help` and the global
`~/.claude/CLAUDE.md`.
