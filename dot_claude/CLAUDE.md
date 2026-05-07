@RTK.md

# Dotfiles

Managed with chezmoi. Source repo: `~/.local/share/chezmoi/`

## Path mapping

| Chezmoi source | Deployed path |
|----------------|---------------|
| `~/.local/share/chezmoi/dot_config/nvim/` | `~/.config/nvim/` |
| `~/.local/share/chezmoi/dot_config/hypr/` | `~/.config/hypr/` |
| `~/.local/share/chezmoi/dot_config/<dir>/` | `~/.config/<dir>/` |
| `~/.local/share/chezmoi/dot_<file>` | `~/.<file>` |

Naming conventions:
- `dot_` prefix → leading `.` in deployed path
- `private_` prefix → file deployed with mode 600
- `.tmpl` suffix → Go template, rendered on apply
- `run_once_` prefix → script run once on `chezmoi apply`
- `run_onchange_` prefix → script run when content changes

## Workflow

Edit files in their deployed locations (`~/.config/`, `~/`), then sync back to chezmoi source and commit:

```bash
chezmoi add ~/.config/<file>
cd ~/.local/share/chezmoi && git add -A && git commit -m "message"
```
