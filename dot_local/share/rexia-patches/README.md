# rexia local tweaks

The checkout at `~/src/rexia` is a fork: **https://github.com/mateuszsip/rexia**,
branch `local-tweaks`, five commits ahead of `hackrdotsh/rexia` (`upstream`).

A fresh Linux machine sets itself up: `run_once_after_install-rexia.sh.tmpl`
clones the fork, installs the pinned Zig 0.17.1 and builds the binary on
first `chezmoi apply` (idempotent — a no-op where those already exist).

The `.patch` files here are generated from those commits (a portable offline
copy — the fork is canonical). Regenerate after adding a tweak:

    git -C ~/src/rexia format-patch upstream/main..local-tweaks \
      -o ~/.local/share/rexia-patches/

## Update and rebuild

    git -C ~/src/rexia pull --rebase upstream main
    cd ~/src/rexia && PATH="$HOME/.local/opt/zig-0.17.1:$PATH" cargo build --release --locked

Zig 0.17 lives at `~/.local/opt/zig-0.17.1` (no system package; the flake's
pin matches it).

## The four tweaks

1. **tabs** — the active tab fills with a raised neutral surface (a Neovim
   buffer-chip look) instead of the accent color.
2. **actions** — `client.host.next` / `client.host.previous` cycle hosts;
   bound in `~/.config/rex/init.lua` to ctrl+alt+shift+j/; (and arrows).
3. **sidebar** — activity marks hug the row's right edge; the hover +/×
   buttons overlay the row absolutely and reveal by visibility only (a
   display toggle panics GPUI between its layout and paint passes —
   "must call prepaint before paint", fixed after it crashed on hover).
4. **clipboard** — programs copy through the terminal (OSC 52): nvim yanks
   this way in every pane, since the rex server strips `WAYLAND_DISPLAY`
   so wl-copy never runs. The stream task already collected each write
   into `PaneModel.clipboard`, but nothing read it — `Workspace::sync`
   now puts it on the system clipboard. (Pasting into a program stays
   ctrl+shift+v: an OSC 52 read query remains unanswered, as in Ghostty
   with clipboard-read off.)
