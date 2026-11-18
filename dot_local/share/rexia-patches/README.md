# rexia local tweaks

The checkout at `~/src/rexia` is a fork: **https://github.com/mateuszsip/rexia**,
branch `local-tweaks`, three commits ahead of `hackrdotsh/rexia` (`upstream`).

The `.patch` files here are generated from those commits (a portable offline
copy — the fork is canonical). Regenerate after adding a tweak:

    git -C ~/src/rexia format-patch upstream/main..local-tweaks \
      -o ~/.local/share/rexia-patches/

## Update and rebuild

    git -C ~/src/rexia pull --rebase upstream main
    cd ~/src/rexia && PATH="$HOME/.local/opt/zig-0.17.1:$PATH" cargo build --release --locked

Zig 0.17 lives at `~/.local/opt/zig-0.17.1` (no system package; the flake's
pin matches it).

## The three tweaks

1. **tabs** — the active tab fills with a raised neutral surface (a Neovim
   buffer-chip look) instead of the accent color.
2. **actions** — `client.host.next` / `client.host.previous` cycle hosts;
   bound in `~/.config/rex/init.lua` to ctrl+alt+shift+j/; (and arrows).
3. **sidebar** — activity marks hug the row's right edge: the hover action
   buttons use `hidden` instead of `invisible`, so they reserve no space.
