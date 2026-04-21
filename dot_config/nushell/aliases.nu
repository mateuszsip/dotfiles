use ~/nu_scripts/aliases/git/git-aliases.nu *
use ~/nu_scripts/aliases/bat/bat-aliases.nu *
use ~/nu_scripts/aliases/eza/eza-aliases.nu *

export alias n = nvim
export alias files = yazi

def ll [] { ls -al | reject inode num_links readonly }

