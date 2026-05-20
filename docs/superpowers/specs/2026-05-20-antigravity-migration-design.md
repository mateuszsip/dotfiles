# Design Spec: Migrate to Antigravity CLI

## 1. Overview
Migrate the workspace from Gemini CLI to Antigravity CLI. Antigravity is the official Go-based replacement for Gemini CLI. The migration will automate the installation, configure the shell environment, and update editor integrations.

## 2. Objectives
- Automate Antigravity CLI installation via chezmoi.
- Ensure the `agy` binary is in the user's PATH.
- Update Neovim `sidekick.nvim` integration to use Antigravity on `<leader>ag`.
- Provide a basic RTK filter for Antigravity.

## 3. Architecture & Components

### 3.1 Installation (`run_once_after_install-antigravity.sh.tmpl`)
A new chezmoi `run_once` script will handle the installation:
- **Command:** `curl -fsSL https://antigravity.google/cli/install.sh | bash`
- **Verification:** Only runs if `agy` is not found in the PATH.
- **Scope:** Linux and macOS (handled by the universal installer script).

### 3.2 Shell Configuration (`dot_config/nushell/env_vars.nu.tmpl`)
Add the Antigravity installation path to the environment:
- **Path:** `~/.antigravity/bin`
- **Target:** Nushell `$env.PATH`.

### 3.3 Editor Integration (`dot_config/nvim/lua/plugins/sidekick.lua`)
Update the `sidekick.nvim` configuration:
- Reassign `<leader>ag` from `gemini` to `antigravity`.
- Keep the `gemini` toggle available on a new binding `<leader>am` (Migration/Memory) or just remove the default binding if the user prefers (current plan: replace existing). *Correction: User explicitly said "replacing gemini cli" on `<leader>ag`.*

### 3.4 Token Optimization (`.rtk/filters.toml`)
Add a placeholder filter for Antigravity:
```toml
[filters.antigravity]
description = "Antigravity CLI output"
match_command = "^agy"
```

## 4. Implementation Details

### Neovim Changes
```lua
{
  "<leader>ag",
  function()
    require("sidekick.cli").toggle({ name = "antigravity", focus = true })
  end,
  desc = "Sidekick Toggle Antigravity",
},
```

### Path Changes
```nu
$env.PATH ++= ['~/.antigravity/bin']
```

## 5. Testing & Validation
1. Run `chezmoi apply` and verify the installation script triggers.
2. Verify `agy --version` works in a new shell.
3. Open Neovim and verify `<leader>ag` opens an Antigravity terminal session.
4. Verify `rtk agy --version` runs through the filter (even if it just passes through for now).
