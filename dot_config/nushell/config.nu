# config.nu
#
# Installed by:
# version = "0.110.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

use ~/nu_scripts/aliases/git/git-aliases.nu *
use ~/nu_scripts/aliases/bat/bat-aliases.nu *
use ~/nu_scripts/aliases/eza/eza-aliases.nu *

use ~/nu_scripts/custom-completions/git/git-completions.nu *
use ~/nu_scripts/custom-completions/gh/gh-completions.nu *
use ~/nu_scripts/custom-completions/aws/aws-completions.nu *
use ~/nu_scripts/custom-completions/bat/bat-completions.nu *
use ~/nu_scripts/custom-completions/auto-generate/completions/yaourt.nu *
use ~/nu_scripts/custom-completions/bitwarden-cli/bitwarden-cli-completions.nu *
use ~/nu_scripts/custom-completions/composer/composer-completions.nu *
use ~/nu_scripts/custom-completions/curl/curl-completions.nu *
use ~/nu_scripts/custom-completions/docker/docker-completions.nu *
use ~/nu_scripts/custom-completions/make/make-completions.nu *
use ~/nu_scripts/custom-completions/zoxide/zoxide-completions.nu *

use std "path add"
path add "/opt/homebrew/bin"

source ~/.zoxide.nu

export alias n = nvim

$env.EDITOR = 'nvim'

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
