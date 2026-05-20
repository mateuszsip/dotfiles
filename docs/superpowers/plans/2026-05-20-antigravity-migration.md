# Antigravity CLI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the workspace from Gemini CLI to Antigravity CLI by automating installation, updating shell PATH, and reconfiguring Neovim keybindings.

**Architecture:** 
- Use a chezmoi `run_once` script for automated installation.
- Update Nushell `env_vars` to include the new binary path.
- Replace Gemini with Antigravity in `sidekick.nvim` configuration.
- Add a basic RTK filter for `agy`.

**Tech Stack:** Bash, Nushell, Lua (Neovim), chezmoi, RTK.

---

### Task 1: Create Antigravity Installation Script

**Files:**
- Create: `run_once_after_install-antigravity.sh.tmpl`

- [ ] **Step 1: Write the installation script**

```bash
#!/bin/bash
# Install Antigravity CLI if not present
set -eufo pipefail

if ! command -v agy &>/dev/null; then
  echo "Installing Antigravity CLI..."
  curl -fsSL https://antigravity.google/cli/install.sh | bash
else
  echo "Antigravity CLI is already installed."
fi
```

- [ ] **Step 2: Set executable permissions**

Run: `chmod +x run_once_after_install-antigravity.sh.tmpl`

- [ ] **Step 3: Commit**

```bash
git add run_once_after_install-antigravity.sh.tmpl
git commit -m "feat: add antigravity installation script"
```

---

### Task 2: Update Shell Environment

**Files:**
- Modify: `dot_config/nushell/env_vars.nu.tmpl`

- [ ] **Step 1: Add Antigravity bin to PATH**

Find the `$env.PATH` definitions and add `~/.antigravity/bin`.

```nu
# ... existing paths
$env.PATH ++= ['~/.local/bin']
$env.PATH ++= ['/usr/local/bin']
$env.PATH ++= ['~/.atuin/bin']
$env.PATH ++= ['~/.antigravity/bin'] # Add this line
```

- [ ] **Step 2: Commit**

```bash
git add dot_config/nushell/env_vars.nu.tmpl
git commit -m "conf: add antigravity to nushell path"
```

---

### Task 3: Update Neovim Sidekick Integration

**Files:**
- Modify: `dot_config/nvim/lua/plugins/sidekick.lua`

- [ ] **Step 1: Replace Gemini with Antigravity on <leader>ag**

Update the keybinding definition for `<leader>ag`.

```lua
-- Old code:
    {
      "<leader>ag",
      function()
        require("sidekick.cli").toggle({ name = "gemini", focus = true })
      end,
      desc = "Sidekick Toggle Gemini",
    },

-- New code:
    {
      "<leader>ag",
      function()
        require("sidekick.cli").toggle({ name = "antigravity", focus = true })
      end,
      desc = "Sidekick Toggle Antigravity",
    },
```

- [ ] **Step 2: Commit**

```bash
git add dot_config/nvim/lua/plugins/sidekick.lua
git commit -m "feat: replace gemini with antigravity in neovim"
```

---

### Task 4: Add RTK Filter for Antigravity

**Files:**
- Modify: `.rtk/filters.toml`

- [ ] **Step 1: Add filter for agy command**

```toml
[filters.antigravity]
description = "Antigravity CLI output"
match_command = "^agy"
```

- [ ] **Step 2: Commit**

```bash
git add .rtk/filters.toml
git commit -m "conf: add rtk filter for antigravity"
```

---

### Task 6: Add Antigravity Config to Chezmoi

**Files:**
- Create: `dot_gemini/antigravity-cli/settings.json.tmpl`
- Create: `dot_gemini/antigravity-cli/keybindings.json`

- [ ] **Step 1: Create settings template**

```json
{
  "colorScheme": "light",
  "trustedWorkspaces": [
    "{{ .chezmoi.homeDir }}"
  ]
}
```

- [ ] **Step 2: Create keybindings file**

Copy content from `~/.gemini/antigravity-cli/keybindings.json`.

- [ ] **Step 3: Commit**

```bash
git add dot_gemini/antigravity-cli/
git commit -m "feat: add antigravity cli config to chezmoi"
```

---

### Task 7: Apply and Verify

- [ ] **Step 1: Apply chezmoi changes**

Run: `chezmoi apply`

- [ ] **Step 2: Verify installation**

Run: `agy --version` (May need a new shell or sourcing env_vars)
Expected: Version output from Antigravity.

- [ ] **Step 3: Verify Neovim binding**

Open Neovim and press `<leader>ag`.
Expected: Terminal split opens with `agy`.
