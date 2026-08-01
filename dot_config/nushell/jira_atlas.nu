# LENDABLE Jira credentials for atlas.nvim.
#
# The API token is fetched from Bitwarden at shell startup so it never lives on
# disk in plaintext. Requires @bitwarden/cli installed globally:
#   npm install -g @bitwarden/cli
# and `bw login` + `BW_SESSION` exported before launching nvim.
#
# Atlas reads these via `vim.env.LENDABLE_JIRA_*` in
# dot_config/nvim/lua/plugins/atlas.lua.

$env.LENDABLE_JIRA_BASE_URL = "https://lendable.atlassian.net"
$env.LENDABLE_JIRA_EMAIL    = "you@lendable.co.uk"

# Bitwarden item name holding the Jira API token. Edit to match your vault.
const jira_token_item = "Jira API token"

if (which bw | is-not-empty) and ("BW_SESSION" in $env) {
  try {
    $env.LENDABLE_JIRA_API_TOKEN = (bw get password $jira_token_item | str trim)
  } catch {|e|
    print $"[jira_atlas.nu] warning: bw lookup failed: ($e.msg)"
  }
} else {
  print "[jira_atlas.nu] warning: bw CLI missing or BW_SESSION unset — Jira views in atlas.nvim will be unavailable"
}