# Hyprland config: hyprlang → Lua migration plan

Status: **phase 0 spike done, nothing in the live config changed**
Date: 2026-10-24
Machine: Hyprland **0.56.2** (hyprlang manager active, no `hyprland.lua` present)

---

## Phase 0 spike results — verified on 0.56.2

Run in a **nested** Hyprland (`hyprland -c <spike>/hyprland.lua`, own socket `wayland-2`).
Live session untouched.

### Confirmed working
| Item | Result |
| --- | --- |
| `hl.config` — every key used in this repo | `config ok` (see caveats) |
| `hl.monitor` / `hl.device` / `hl.workspace_rule` at runtime via `hyprctl eval` | `ok` — script replacements are viable |
| All 39 dispatcher mappings from this repo (`hl.dsp.*`) | 39/39 construct cleanly |
| `hl.curve` bezier + spring | ok |
| `hl.get_config("cursor.zoom_factor")` | returns `number` → zoom binds work |
| `hl.config({cursor={zoom_factor=…}})` at runtime | 1.0 → 2.0 → 1.0 |
| `hl.on("hyprland.start", …)` | **fires** (autostart path is good) |
| `require` with dots, slashes, `./` and `pcall(require, …)` | all forms ok |
| `io.open` / `os.getenv` / `io.popen` | available (toggle sniffing works) |
| Broken config on `hyprctl reload` | session survives, `configerrors` reports the line, old config kept |
| `hyprctl reload full-reset` | **accepted on 0.56.2** — rollback needs no restart |
| `hyprctl getoption` under the Lua manager | still works |

### Corrections to the original plan

1. **`hl.animation` takes `bezier=` / `spring=`, not `curve=`.** The wiki's signature line says `curve` but every example says `bezier`; the runtime enforces `bezier`/`spring`:
   `hl.animation("global"): bezier or spring is required`. Section 4 below is fixed.
2. **Hyprland embeds Lua 5.5**, not 5.4 (visible from the `require` search paths). System `luac` is 5.4, so `luac -p` is only an approximation.
3. **`--verify-config` is a real gate.** It parses the config offline, prints `config ok` or the error, and **exits 1 on error**. This replaces `luac -p` as the primary validation step.
4. **Parse-time validation is much better than expected.** Both of these are caught before startup:
   - `unknown config key 'general.not_a_real_option'`
   - `hl.window_rule: unknown field 'not_a_real_effect'`
5. **No compatibility shim for old dispatchers.** `hyprctl dispatch togglefloating` fails with
   `hl.dispatch: expected a dispatcher (e.g. hl.dsp.window.close())`. Phase 6 is mandatory, not optional.
6. **`hyprctl keyword` is hard-removed**:
   `keyword can't work with non-legacy parsers. Use eval.`

### Error classes (determines how defensive the tree must be)

| Class | Effect |
| --- | --- |
| Hyprland argument error (bad option, bad effect, missing required arg) | logged, **execution continues** |
| Lua runtime error (`nil` call in config) | **aborts that file**, other `require`d files still load |
| `require` of a missing module | **fatal** for that file, with traceback (use `pcall`) |

### Spike artefacts
`/tmp/opencode/hyprlua-spike/` — `hyprland.lua`, `checks.lua` (39 dispatchers), `t/*.lua` (failure modes, real option keys).

---

## 1. Why now

| Fact | Source |
| --- | --- |
| Hyprland 0.55 moved the config to **Lua** (`~/.config/hypr/hyprland.lua`) | hypr.land/news/26_lua, wiki Configuring/Start |
| hyprlang is **deprecated**, supported "for 1–2 releases starting from 0.55", then dropped | news post 2026-04-26 |
| **New config features are no longer added to hyprlang** | news post |
| The `.lua` vs `.conf` choice is checked **once at startup**; switching needs a restart | news post |
| hypr* tools (`hypridle`, `hyprlock`, `hyprsunset`, xdph) **keep hyprlang** | news post |

We are on 0.56.2 → the drop lands in **0.57 or 0.58**. This is a deadline, not a preference.

Also verified live:
- `hyprctl eval` / `repl` exist but **only work under the Lua manager** (`eval is only supported with the lua config manager`).
- API stubs ship at `/usr/share/hypr/stubs/hl.meta.lua` (1777 lines) — usable as an LSP library and as the authoritative API list.
- `luac` 5.4 is installed, so config files can be syntax-checked offline.

---

## 2. Scope — what converts and what doesn't

### Converts (Hyprland config manager)

| File | Lines | Content |
| --- | --- | --- |
| `hyprland.conf` | 36 | 11 `source`, 6 windowrules, toggles glob |
| `base/looknfeel.conf` | ~90 | general, decoration, blur, group/groupbar, animations, dwindle, scrolling, master, misc, cursor, binds |
| `base/bindings/*.conf` (4) | ~200 | ~130 binds |
| `base/apps/*.conf` (17) | ~120 | windowrules + 1 layerrule |
| `base/windows.conf`, `base/apps.conf` | ~25 | rule order + source list |
| `base/input.conf`, `input.conf.tmpl` | ~80 | input, touchpad, device, gesture, 2 windowrules |
| `base/envs.conf` | ~20 | `env`, `xwayland`, `ecosystem` |
| `base/autostart.conf`, `autostart.conf` | 16 | `exec-once` |
| `monitors.conf` | 14 | `monitor`, 2 switch binds, 1 exec-once |
| `workspaces.conf` | 2 | empty (nwg-displays header) |
| `looknfeel.conf` (top level) | 24 | overrides: rounding, border colour |
| `theme/hyprland.conf.tmpl` | 2 | palette → border colours |

### Does **not** convert
`hypridle.conf`, `hyprlock.conf.tmpl`, `hyprsunset.conf`, `xdph.conf`, `theme/hyprlock.conf.tmpl` — hypr* tools still read hyprlang. Leave untouched.

### Second, larger blast radius: `hyprctl` call sites

`hyprctl keyword` **does not exist under the Lua manager**, and `hyprctl dispatch` now takes a **Lua expression** (`hyprctl dispatch 'hl.dsp.focus({workspace="3"})'`). Any script doing either breaks the moment the manager switches.

| Script | Breaking calls | Replacement |
| --- | --- | --- |
| `sys-window` | 8 dispatches (`togglefloating`, `resizeactive`, `moveactive`, `centerwindow`, `pin`, `alterzorder`, `tagwindow`, `closewindow`, `setprop`) | `hyprctl dispatch 'hl.dsp.window.…'` |
| `sys-monitor` | `keyword monitor …` | `hyprctl eval 'hl.monitor({…})'` |
| `sys-touchpad` | 2× `keyword device[…]:enabled` | `hyprctl eval 'hl.device({name=…, enabled=…})'` |
| `sys-workspace-layout` | `keyword workspace …, layout:…` | `hyprctl eval 'hl.workspace_rule({…})'` |
| `sys-brightness` | 2× `dispatch dpms on/off` | `hyprctl dispatch 'hl.dsp.dpms({action="…"})'` |
| `sys-launch` | `dispatch focuswindow address:` | `hl.dsp.focus({window="address:…"})` |
| `sys-theme-reload` | `dispatch exec -- sys-background` | `hl.dsp.exec_cmd("sys-background")` |
| `utilities.conf` zoom binds | `keyword cursor:zoom_factor`, `getoption` | `hl.get_config` / `hl.config` inside a bind callback |
| `monitors.conf` switch binds | `keyword monitor` | drop — `hl.monitor` + `hyprctl eval` |

Info-only calls (`clients`, `monitors`, `devices`, `activewindow`, `workspaces`, `binds`) are unaffected; `getoption` needs re-verification.

**This is the sharp edge of the whole migration: the scripts and the config manager must flip in the same atomic step.**

---

## 3. Three architectural problems

### A. Runtime toggles (`~/.local/state/hypr/toggles/*.conf`)

Today `hyprland.conf` ends with `source = ~/.local/state/hypr/toggles/*.conf`; `sys-window` / `sys-monitor` / `sys-touchpad` write **hyprlang snippets** there and call `hyprctl reload`. There is no `source` in Lua and the snippets are unparseable.

Producers (5 real toggles, plus `flags.conf` which exists only to keep the glob non-empty):

| File | Written by | Effect |
| --- | --- | --- |
| `window-no-gaps.conf` | `sys-window gaps` | `general.gaps_*`, `border_size`, `decoration.rounding` |
| `single-window-aspect-ratio.conf` | `sys-window square-aspect` | `layout.single_window_aspect_ratio` |
| `internal-monitor-disable.conf` | `sys-monitor internal off` | `monitor=eDP-1,disable` |
| `internal-monitor-mirror.conf` | `sys-monitor mirror on` | `monitor=…,mirror,…` |
| `touchpad-disabled.conf` | `sys-touchpad off` | `device{name,enabled=false}` |

**Recommendation — keep the state-dir model, change the payload to Lua.** `hyprland.lua` reads a fixed list of known toggle names (Lua has no directory glob, and a fixed list is deterministic and avoids `io.popen("ls")`):

```lua
local dir = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME").."/.local/state").."/hypr/toggles/"
local function toggled(name)
  local f = io.open(dir..name..".lua", "r"); if f then f:close() return true end
  return false
end
if toggled("window-no-gaps") then hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 } }) end
```

Scripts write `.lua` one-liners (`hl.config({...})`, `hl.monitor({...})`, `hl.device({...})`) and still `hyprctl reload`. Same semantics, same persistence, no new abstraction. `flags.conf` disappears.

**As built (phases 1 and 5):** the loader in `hyprland.lua` is an explicit name list, each
`pcall(dofile, …)` so one broken toggle cannot take the config down, and the payload is executed
with `dofile` (not `require`) so it re-runs on every reload. `hl.monitor`/`hl.device` at load time
are the same calls the spike validated at runtime.

**The writer scripts flip in phase 6, not phase 5.** They are deployed to `~/.local/bin` by an
ordinary `chezmoi apply`, so changing them while the live session still runs hyprlang would break
toggling immediately. They change together with the other `hyprctl` call sites, in the commit that
must land atomically with the cutover. Until then they keep writing `*.conf`, which the live
`hyprland.conf` still sources; any toggle set before the cutover is simply absent afterwards
(re-toggle once after restart).

Optional later improvement: `hyprctl repl 'dofile("…")'` applies a toggle without a full reload. Not worth doing in v1.

### B. Environment variables

`base/envs.conf` sets ~20 env vars and `theme/gum.env.conf.tmpl` adds **116 `env =` lines** (whole-file wrapped in `# hyprlang noerror true/false` because a missing palette key would otherwise be fatal).

Upstream now says uwsm users should put env in `~/.config/uwsm/env` instead of `hyprland.lua`. We do use uwsm.

**Recommendation — keep `hl.env()` for v1.**
- It preserves exact current behaviour, including `systemctl --user import-environment` + `dbus-update-activation-environment --all` in `base/autostart.conf` (which is what makes waybar/mako see the vars).
- The move to `uwsm/env` is a separate, independently testable change and can be phase 7+ if ever.

Two cleanups fall out for free either way:
- hyprlang needed `##` to escape a leading `#`; Lua strings need plain `#`. So `env = FOREGROUND,##100F0F` → `hl.env("FOREGROUND", "#100F0F")`.
- The `noerror` wrapper is replaced by `pcall(require, …)`, or dropped entirely since a generated Lua file can't "partially fail" the same way.

### C. `nwg-displays`

`monitors.conf` and `workspaces.conf` are generated by **nwg-displays 0.5.0**, which emits hyprlang `monitor=` / `workspace=` lines. Under the Lua manager those writes are dead.

**Recommendation — retire nwg-displays from the workflow** and hand-own `monitors.lua` (it is 2 monitors + 2 switch binds). If you want to keep it, it needs a wrapper that translates its output; not worth it for 2 monitors.

**As built:** `monitors.lua` is hand-owned; the two internal-panel binds became Lua-function
dispatchers (`hl.monitor(...)` directly, no `hyprctl`, no shell). `nwg-displays` is still listed in
`packages_arch.txt` and is dropped in phase 7, together with the files it generated.

**Dead files found while migrating** (not loaded today, so behaviour is unchanged by not porting
them):
- `workspaces.conf` — nwg-displays output that `hyprland.conf` never sources.
- `base/apps/davinci-resolve.conf` — not listed in `base/apps.conf`.

Both are deleted in phase 7 rather than ported.
Also note `sys-menu` opens `~/.config/hypr/monitors.conf` in the editor; that path moves to
`monitors.lua` in phase 6.

---

## 4. Translation rules

### Structure

| hyprlang | Lua |
| --- | --- |
| `source = path` | `require("base.looknfeel")` — separate scope, errors are isolated per file |
| `# hyprlang noerror true` | `local ok, err = pcall(require, "maybe")` |
| `$var = value` | `local var = value` |
| `section { key = v }` | `hl.config({ section = { key = v } })` |
| `col.active_border = rgba(a) rgba(b) 45deg` | `col = { active_border = { colors = { "rgba(a)", "rgba(b)" }, angle = 45 } }` |

**Gradient gotcha:** the hyprlang gradient *string* is rejected in Lua mode
(`invalid color "rgba(33ccffee) rgb(00ff99ee) 45deg"`), even though the stub types the
field as `string|HL.Gradient`. It must be the table form. Single colours stay strings.
`hl.get_config` always returns gradients as a table (`{ colors = { 0xFF100F0F }, angle = 0 }`).

**Layering:** repeated `hl.config({ … })` calls *merge* — they do not replace a subtree.
Verified: setting `decoration.rounding` afterwards keeps `decoration.shadow.*` from the
earlier call, which is what makes the base → theme → personal override chain behave like
hyprlang did.

### Top-level calls

| hyprlang | Lua |
| --- | --- |
| `env = K,V` | `hl.env("K", "V")` |
| `exec-once = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd(cmd) end)` |
| `exec-once = [workspace 2 silent] cmd` | `hl.exec_cmd(cmd, { workspace = "2 silent" })` |
| `monitor = out,mode,pos,scale` | `hl.monitor({ output = …, mode = …, position = …, scale = … })` |
| `monitor = …,bitdepth,10` | `bitdepth = 10` field |
| `workspace = 3, layout:scrolling` | `hl.workspace_rule({ workspace = "3", layout = "scrolling" })` |
| `windowrule = …` | `hl.window_rule({ match = {…}, …effects })` |
| `layerrule = no_anim on, match:namespace x` | `hl.layer_rule({ match = { namespace = "x" }, no_anim = true })` |
| `bezier = name,x1,y1,x2,y2` | `hl.curve(name, { type = "bezier", points = {{x1,y1},{x2,y2}} })` |
| `animation = leaf, on, speed, curve, style` | `hl.animation({ leaf = …, enabled = true, speed = …, bezier = "…", style = "…" })` — **`bezier`, not `curve`** (spike) |
| `device { name = … }` | `hl.device({ name = …, … })` |
| `gesture = 3, horizontal, workspace` | `hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })` |
| `binds { … }` | `hl.config({ binds = { … } })` |
| `ecosystem { … }` | `hl.config({ ecosystem = { … } })` |
| `xwayland { … }` | `hl.config({ xwayland = { … } })` |

### Binds

Suffix flags map 1:1 into the options table. Used in this repo:

| hyprlang | Lua |
| --- | --- |
| `bind` | `hl.bind(keys, dsp)` |
| `bindd` (d=description) | `{ description = "…" }` |
| `bindl` (l=locked) | `{ locked = true }` |
| `bindle` (l+e=repeat) | `{ locked = true, repeating = true }` |
| `bindeld` | `{ repeating = true, locked = true, description = "…" }` |
| `bindld`, `binddl` | `{ locked = true, description = "…" }` |
| `bindmd` (m=mouse) | `{ mouse = true, description = "…" }` |
| `binddr` (d+r=release) | `{ release = true, description = "…" }` |

Keys: `"SUPER + SHIFT + Q"`. Keycodes unchanged: `"SUPER + code:10"`. Switches: `"SUPER + switch:on:Lid Switch"`.

**Mouse binds** (`bindm`) take no extra option — `hl.bind("SUPER + mouse:272", hl.dsp.window.drag())`
is the whole thing. Don't be alarmed when `hyprctl binds -j` reports `mouse: false`: the `mouse`
flag exists only to route hyprlang's `bindm` to the legacy `"mouse"` dispatcher. Lua binds dispatch
through `__lua` instead, and `onMouseEvent` → `handleKeybinds` matches on the `mouse:N` key name,
so they fire normally. `hl.unbind("SUPER + SPACE")` exists if a key must be redefined.

**Duplicates are preserved.** `ALT + TAB` carries two actions (focus next + raise), exactly as two
hyprlang `bind` lines did; both register and both fire.

**Verified live:** a nested instance loaded all 183 binds (matching the source count), with
descriptions, `locked`/`repeat`/`release` flags and the lid-switch binds intact.

### Dispatchers used in this repo → `hl.dsp.*`

| hyprlang | Lua |
| --- | --- |
| `exec, cmd` | `hl.dsp.exec_cmd("cmd")` |
| `killactive` | `hl.dsp.window.close()` |
| `togglefloating` | `hl.dsp.window.float()` |
| `fullscreen, 0` / `, 1` | `hl.dsp.window.fullscreen()` / `({ mode = "maximized" })` |
| `fullscreenstate, 0 2` | `hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })` |
| `pseudo` | `hl.dsp.window.pseudo()` |
| `layoutmsg, togglesplit` | `hl.dsp.layout("togglesplit")` |
| `movefocus, l` | `hl.dsp.focus({ direction = "l" })` |
| `focusmonitor, +1` | `hl.dsp.focus({ monitor = "+1" })` |
| `focuswindow address:…` | `hl.dsp.focus({ window = "address:…" })` |
| `workspace, 1` / `e+1` | `hl.dsp.focus({ workspace = 1 })` / `({ workspace = "e+1" })` |
| `movetoworkspace, 1` | `hl.dsp.window.move({ workspace = 1 })` |
| `movetoworkspacesilent, 1` | `hl.dsp.window.move({ workspace = 1, follow = false })` |
| `togglespecialworkspace, scratchpad` | `hl.dsp.workspace.toggle_special("scratchpad")` |
| `movecurrentworkspacetomonitor, l` | `hl.dsp.workspace.move({ monitor = "l" })` |
| `swapwindow, l` | `hl.dsp.window.swap({ direction = "l" })` |
| `cyclenext` / `, prev` | `hl.dsp.window.cycle_next()` / `({ next = false })` |
| `bringactivetotop` | `hl.dsp.window.alter_zorder({ mode = "top" })` |
| `resizeactive, -100 0` | `hl.dsp.window.resize({ x = -100, y = 0, relative = true })` |
| `movewindow` / `resizewindow` (+`m`) | `hl.dsp.window.drag()` / `.resize()` with `{ mouse = true }` |
| `togglegroup` | `hl.dsp.group.toggle()` |
| `moveintogroup, l` | `hl.dsp.window.move({ into_group = "l" })` |
| `moveoutofgroup` | `hl.dsp.window.move({ out_of_group = true })` |
| `changegroupactive, f` / `, b` / `, N` | `hl.dsp.group.next()` / `.prev()` / `.active({ index = N })` |
| `sendshortcut, CTRL, Insert, activewindow` | `hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert", window = "activewindow" })` |
| `tagwindow +pop` | `hl.dsp.window.tag({ tag = "+pop" })` |
| `setprop …, opaque, toggle` | `hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" })` |
| `dpms off` | `hl.dsp.dpms({ action = "disable" })` |
| `exit` | use `uwsm stop` instead (uwsm warning in docs) |

### Window-rule effects

| hyprlang | Lua |
| --- | --- |
| `float on` / `off` | `float = true` / `false` |
| `opacity 0.985 0.96` | `opacity = "0.985 0.96"` |
| `size 600 338` | `size = { 600, 338 }` |
| `move (monitor_w-window_w-40) (monitor_h*0.04)` | `move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" }` |
| `tag +pip` / `-default-opacity` | `tag = "+pip"` / `"-default-opacity"` (toggle = no prefix) |
| `idle_inhibit fullscreen` | `idle_inhibit = "fullscreen"` |
| `suppress_event maximize` | `suppress_event = "maximize"` |
| `no_screen_share on` | `no_screen_share = true` |
| `workspace special silent` | `workspace = "special silent"` |
| `scroll_touchpad 1.5` | `scroll_touchpad = 1.5` |
| `match:class X, match:float 1` | `match = { class = "X", float = true }` |

The named block form (`windowrule { name = …; match:class = …; effect = on }`) maps to a single
`hl.window_rule({ name = "…", match = { class = "…" }, effect = true })`.

**`davinci-resolve.conf` is dead config:** it is not listed in `base/apps.conf`, so it has never
loaded. It is not migrated (no Lua equivalent) and the file is left in place for phase 7.

**Rules only apply to windows mapped after they are declared** — `hl.window_rule` at runtime does
not retro-apply to existing windows, same as hyprlang. Verified live with a probe rule
(`float` + `size` + `pin`) on a freshly spawned window.

Rule **order still matters** and is preserved by `require` order.

---

## 5. Target file layout

Keep the existing tree and only change extensions — smallest reviewable diff, keeps the de-omarchy ownership comments meaningful.

```
dot_config/hypr/
  hyprland.lua.tmpl          # entry: requires in order + toggles + inline rules
  base/
    looknfeel.lua
    envs.lua                 # hl.env + xwayland + ecosystem
    input.lua                # input + misc
    autostart.lua            # hl.on("hyprland.start", …)
    windows.lua              # rules + require loop over apps
    apps.lua                 # for _, m in ipairs({…}) do require("base.apps."..m) end
    apps/*.lua               # 17 files
    bindings/*.lua           # 4 files
  input.lua.tmpl             # keeps archarm conditional
  bindings.lua.tmpl          # keeps archarm conditional
  looknfeel.lua
  autostart.lua
  monitors.lua
  theme/hyprland.lua.tmpl    # palette → hl.config colours
```

Notes:
- `bindings.conf.tmpl` / `input.conf.tmpl` stay chezmoi templates — only the extension changes, the `{{- if eq .chezmoi.osRelease.id "archarm" }}` blocks are untouched.
- `theme/hyprland.conf.tmpl` shrinks to ~4 lines (no `$variable` indirection).
- `base/apps.conf` collapses from 16 `source` lines to a 4-line `ipairs` loop.
- `workspaces.conf` disappears (empty file, nwg-displays residue).

---

## 6. Phases

Follows the repo convention: phased commits, no per-phase branch, `TEMP(hyprlua)` markers where debt is carried.

| Phase | Commit | Work | Risk |
| --- | --- | --- | --- |
| **0** | *(none — scratch)* | **DONE** — nested spike, all questions answered (see results at top) | none |
| **1** | `[hyprlua] phase 1: lua modules for env, autostart and input` | **DONE** — `hyprland.lua` + `require` graph (stubs for later phases) + `envs`/`autostart`/`input` + `theme/gum-env.lua.tmpl` | none — not deployed |
| **2** | `[hyprlua] phase 2: look and feel, animations and theme colours` | **DONE** — `base/looknfeel.lua`, `looknfeel.lua`, `theme/hyprland.lua.tmpl`; gradients as tables | none |
| **3** | `[hyprlua] phase 3: binds` | **DONE** — 5 modules, 183 binds (verified live in a nested instance) | mechanical, high volume |
| **4** | `[hyprlua] phase 4: window rules` | **DONE** — `windows.lua`, `apps.lua` + 16 app modules (rule-for-rule parity); effect application verified live | order-sensitive |
| **5** | `[hyprlua] phase 5: monitors` | **DONE** — `monitors.lua` hand-owned (nwg-displays retired), panel binds as Lua functions. Toggle *writers* deferred to phase 6 with the other scripts | low |
| **6** | `[hyprlua] phase 6: hyprctl call sites` | 7 scripts + zoom binds → Lua expressions | **medium** |
| **7** | `[hyprlua] phase 7: cutover` | `chezmoi apply` + full restart; verify; delete `hyprland.conf` + hyprlang tree | **high, but reversible** |

Phases 1–6 are inert: nothing changes until `hyprland.lua` is deployed **and** the session restarts. `chezmoi apply` at phase 7 is the single atomic flip, and phase 6 must be in the same apply.

**Cutover guard.** Hyprland switches to Lua mode purely on `hyprland.lua` existing, so a
routine `chezmoi apply` during phases 1–6 would silently migrate the next session to a
half-built config. `hyprland.lua` is therefore listed in `.chezmoiignore.tmpl`
(`.config/hypr/hyprland.lua`) and is **not** managed until phase 7 removes that line.
Verified with `chezmoi managed`: the entry file is absent, the module files are present
(unreferenced, therefore harmless).

`hyprland.lua` is plain `.lua`, not `.tmpl` — it needs no template data.

`TEMP(hyprlua)` markers go in every hyprlang file being replaced (`hyprland.conf`,
`base/*.conf`, …) and are deleted in phase 7, per repo convention.

---

## 7. Validation & rollback

**Per phase (offline, no compositor):**
```bash
docs/hyprlua-validate.sh .                  # stage + render + verify the whole tree
```
It copies `dot_config/hypr` to a scratch dir, renders every `.tmpl` through
`chezmoi execute-template`, then runs the gate below against the entry file. Rendering
matters: a template bug only shows up in the rendered output, never in the source.

```bash
hyprland -c <file> --verify-config          # parses the config; "config ok", exit 1 on error
```
This is the primary gate — it validates Lua syntax *and* every config key / window-rule
effect / dispatcher argument, and it runs headless. `luac -p` is only a cheap pre-check
and is 5.4 while Hyprland embeds 5.5.

For the templated entry file:
```bash
chezmoi execute-template < dot_config/hypr/hyprland.lua.tmpl > /tmp/x.lua
hyprland -c /tmp/x.lua --verify-config
```

**Phase 0 spike (nested, safe) — DONE, see results at the top.**
To re-run:
```bash
hyprland -c /tmp/opencode/hyprlua-spike/hyprland.lua      # nested window, own socket
hyprctl instances                                        # find the nested pid
hyprctl -i <sig> repl 'dofile("/tmp/opencode/hyprlua-spike/checks.lua")'
hyprctl -i <sig> configerrors
```

**Phase 7 cutover:**
```bash
chezmoi diff                        # review every file
chezmoi apply
# full restart (required — manager check is startup-only)
hyprctl configerrors                # must be empty
```
Then walk: binds, workspaces, groups, scratchpad, float/pin, monitors, mirror, touchpad toggle, gaps toggle, theme reload, each `sys-*` script.

**Rollback:** delete `~/.config/hypr/hyprland.lua` (or `chezmoi apply` the previous commit) and restart. `hyprland.conf` stays in the repo untouched until phase 7 succeeds, so rollback is one file deletion. If `hyprctl reload full-reset` exists on 0.56.2, rollback does not even need a restart.

**Emergency:** Hyprland grants `SUPER+Q` / `SUPER+R` / `SUPER+M` when the config fails before binds load — so a broken phase 7 is recoverable in-session, not a lockout.

---

## 8. Risks

1. **Atomic cutover coupling (highest) — now confirmed, not suspected.** There is no shim: old `hyprctl dispatch` and `hyprctl keyword` both fail outright under the Lua manager. Config + 7 scripts must flip together. Mitigated by `--verify-config`, the nested harness, and the keep-`hyprland.conf` rollback.
2. **`require` errors are fatal per file, and `require` of a *missing* module is a hard error** (not protected). Keep module names exact; use `pcall(require, …)` for the generated/optional ones (gum env, toggles).
3. **Rule ordering.** `windows.lua` → app rules → `tag +default-opacity` opacity rule. `require` order must match; a reorder silently changes opacity handling everywhere.
4. **`bindings` callbacks must not block.** Lua binds run on the compositor loop. All existing `exec` binds stay `hl.dsp.exec_cmd`; the zoom binds (`hl.get_config` + `hl.config`) are the only inline-logic ones and are non-blocking by construction. Never put `io.popen`/`wl-paste`/`sleep` in a Lua bind.
5. **nwg-displays** writes hyprlang — dead under Lua. Retire it (recommended) or it silently stops persisting monitor changes.
6. **`animations.enabled = yes, please :)`** is a hyprlang joke value; Lua needs `true`.
7. **`getoption`** still works under the Lua manager (spike), but returns formatted strings for composite types (`css gap data: 5 5 5 5`). Use `hl.get_config` in scripts — it returns real values (`number`, `boolean`, `table`).
8. **Lua 5.5 vs `luac` 5.4.** `luac -p` can pass code Hyprland rejects, or vice versa. Trust `--verify-config`.
9. **`hl.animation` needs `bezier`/`spring`,** not the `curve` the wiki signature line advertises.
10. **Arch package rollback.** If 0.57 drops hyprlang before phase 7 lands, pinning `hyprland` in `pacman.conf` is the only fallback. Worth knowing, not worth doing now.

---

## 9. Open questions

Resolved by the spike (defaults assumed, say if you disagree):
- Toggle payload → `.lua` snippets in `~/.local/state/hypr/toggles/`, read at config load.
- Env vars → keep `hl.env()`.
- nwg-displays → retire.
- Rollback → `hyprctl reload full-reset` works on 0.56.2, so a bad cutover can be undone without restarting (the forward cutover still needs a restart, since only the `.lua`-exists check forces the manager at startup).

Still open:
1. **Cutover timing** — one session restart at phase 7. The 2 ghostty windows on workspaces 2 and 3 will not be restored.
2. **Scope of phase 6** — convert the 7 `sys-*` scripts to Lua expressions (required), but `utilities.conf`'s zoom binds and `monitors.conf`'s switch binds also embed `hyprctl keyword` and must move in the same commit. Confirm you want those folded into phase 6 rather than split out.
