-- Tiling, focus, workspaces and groups.
-- Migrated from base/bindings/tiling-v2.conf; that file stays authoritative until phase 7.

-- Close windows
hl.bind("SUPER + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("sys-window close-all"), { description = "Close all windows" })

-- Control tiling
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle window split" })
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Pseudo window" }) -- dwindle
hl.bind("SUPER + T", hl.dsp.window.float(), { description = "Toggle window floating/tiling" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen(), { description = "Full screen" })
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }), { description = "Tiled full screen" })
hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Full width" })
hl.bind("SUPER + O", hl.dsp.exec_cmd("sys-window pop"), { description = "Pop window out (float & pin)" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("sys-workspace-layout"), { description = "Toggle workspace layout" })

-- Move focus with SUPER + arrow keys
hl.bind("SUPER + LEFT", hl.dsp.focus({ direction = "l" }), { description = "Focus on left window" })
hl.bind("SUPER + RIGHT", hl.dsp.focus({ direction = "r" }), { description = "Focus on right window" })
hl.bind("SUPER + UP", hl.dsp.focus({ direction = "u" }), { description = "Focus on above window" })
hl.bind("SUPER + DOWN", hl.dsp.focus({ direction = "d" }), { description = "Focus on below window" })

-- Switch workspaces with SUPER + [1-9; 0]
hl.bind("SUPER + code:10", hl.dsp.focus({ workspace = 1 }), { description = "Switch to workspace 1" })
hl.bind("SUPER + code:11", hl.dsp.focus({ workspace = 2 }), { description = "Switch to workspace 2" })
hl.bind("SUPER + code:12", hl.dsp.focus({ workspace = 3 }), { description = "Switch to workspace 3" })
hl.bind("SUPER + code:13", hl.dsp.focus({ workspace = 4 }), { description = "Switch to workspace 4" })
hl.bind("SUPER + code:14", hl.dsp.focus({ workspace = 5 }), { description = "Switch to workspace 5" })
hl.bind("SUPER + code:15", hl.dsp.focus({ workspace = 6 }), { description = "Switch to workspace 6" })
hl.bind("SUPER + code:16", hl.dsp.focus({ workspace = 7 }), { description = "Switch to workspace 7" })
hl.bind("SUPER + code:17", hl.dsp.focus({ workspace = 8 }), { description = "Switch to workspace 8" })
hl.bind("SUPER + code:18", hl.dsp.focus({ workspace = 9 }), { description = "Switch to workspace 9" })
hl.bind("SUPER + code:19", hl.dsp.focus({ workspace = 10 }), { description = "Switch to workspace 10" })

-- Move active window to a workspace with SUPER + SHIFT + [1-9; 0]
hl.bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 }), { description = "Move window to workspace 1" })
hl.bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 }), { description = "Move window to workspace 2" })
hl.bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 }), { description = "Move window to workspace 3" })
hl.bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 }), { description = "Move window to workspace 4" })
hl.bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 }), { description = "Move window to workspace 5" })
hl.bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 }), { description = "Move window to workspace 6" })
hl.bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 }), { description = "Move window to workspace 7" })
hl.bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 }), { description = "Move window to workspace 8" })
hl.bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 }), { description = "Move window to workspace 9" })
hl.bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }), { description = "Move window to workspace 10" })

-- Move active window silently to a workspace with SUPER + SHIFT + ALT + [1-9; 0]
hl.bind("SUPER + SHIFT + ALT + code:10", hl.dsp.window.move({ workspace = 1, follow = false }), { description = "Move window silently to workspace 1" })
hl.bind("SUPER + SHIFT + ALT + code:11", hl.dsp.window.move({ workspace = 2, follow = false }), { description = "Move window silently to workspace 2" })
hl.bind("SUPER + SHIFT + ALT + code:12", hl.dsp.window.move({ workspace = 3, follow = false }), { description = "Move window silently to workspace 3" })
hl.bind("SUPER + SHIFT + ALT + code:13", hl.dsp.window.move({ workspace = 4, follow = false }), { description = "Move window silently to workspace 4" })
hl.bind("SUPER + SHIFT + ALT + code:14", hl.dsp.window.move({ workspace = 5, follow = false }), { description = "Move window silently to workspace 5" })
hl.bind("SUPER + SHIFT + ALT + code:15", hl.dsp.window.move({ workspace = 6, follow = false }), { description = "Move window silently to workspace 6" })
hl.bind("SUPER + SHIFT + ALT + code:16", hl.dsp.window.move({ workspace = 7, follow = false }), { description = "Move window silently to workspace 7" })
hl.bind("SUPER + SHIFT + ALT + code:17", hl.dsp.window.move({ workspace = 8, follow = false }), { description = "Move window silently to workspace 8" })
hl.bind("SUPER + SHIFT + ALT + code:18", hl.dsp.window.move({ workspace = 9, follow = false }), { description = "Move window silently to workspace 9" })
hl.bind("SUPER + SHIFT + ALT + code:19", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "Move window silently to workspace 10" })

-- Control scratchpad
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle scratchpad" })
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), { description = "Move window to scratchpad" })

-- TAB between workspaces
hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind("SUPER + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind("SUPER + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Former workspace" })

-- Move workspaces to other monitors
hl.bind("SUPER + SHIFT + ALT + LEFT", hl.dsp.workspace.move({ monitor = "l" }), { description = "Move workspace to left monitor" })
hl.bind("SUPER + SHIFT + ALT + RIGHT", hl.dsp.workspace.move({ monitor = "r" }), { description = "Move workspace to right monitor" })
hl.bind("SUPER + SHIFT + ALT + UP", hl.dsp.workspace.move({ monitor = "u" }), { description = "Move workspace to up monitor" })
hl.bind("SUPER + SHIFT + ALT + DOWN", hl.dsp.workspace.move({ monitor = "d" }), { description = "Move workspace to down monitor" })

-- Swap active window with the one next to it with SUPER + SHIFT + arrow keys
hl.bind("SUPER + SHIFT + LEFT", hl.dsp.window.swap({ direction = "l" }), { description = "Swap window to the left" })
hl.bind("SUPER + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window to the right" })
hl.bind("SUPER + SHIFT + UP", hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind("SUPER + SHIFT + DOWN", hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })

-- Cycle through applications on active workspace
-- Two actions share a key: hyprlang ran both, so do the same here.
hl.bind("ALT + TAB", hl.dsp.window.cycle_next(), { description = "Focus on next window" })
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }), { description = "Focus on previous window" })
hl.bind("ALT + TAB", hl.dsp.window.alter_zorder({ mode = "top" }), { description = "Reveal active window on top" })
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.alter_zorder({ mode = "top" }), { description = "Reveal active window on top" })

-- Cycle through monitors
hl.bind("CTRL + ALT + TAB", hl.dsp.focus({ monitor = "+1" }), { description = "Focus on next monitor" })
hl.bind("CTRL + ALT + SHIFT + TAB", hl.dsp.focus({ monitor = "-1" }), { description = "Focus on previous monitor" })

-- Resize active window
hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { description = "Expand window left" }) -- - key
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { description = "Shrink window left" }) -- = key
hl.bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { description = "Shrink window up" })
hl.bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { description = "Expand window down" })

-- Scroll through existing workspaces with SUPER + scroll
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll active workspace forward" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll active workspace backward" })

-- Move/resize windows with mainMod + LMB/RMB and dragging.
-- The mouse flag is implied by the `mouse:N` key, so drag()/resize() take no options.
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { description = "Resize window" })

-- Toggle groups
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Toggle window grouping" })
hl.bind("SUPER + ALT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Move active window out of group" })

-- Join groups
hl.bind("SUPER + ALT + LEFT", hl.dsp.window.move({ into_group = "l" }), { description = "Move window to group on left" })
hl.bind("SUPER + ALT + RIGHT", hl.dsp.window.move({ into_group = "r" }), { description = "Move window to group on right" })
hl.bind("SUPER + ALT + UP", hl.dsp.window.move({ into_group = "u" }), { description = "Move window to group on top" })
hl.bind("SUPER + ALT + DOWN", hl.dsp.window.move({ into_group = "d" }), { description = "Move window to group on bottom" })

-- Navigate a single set of grouped windows
hl.bind("SUPER + ALT + TAB", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind("SUPER + ALT + SHIFT + TAB", hl.dsp.group.prev(), { description = "Previous window in group" })

-- Window navigation for grouped windows
hl.bind("SUPER + CTRL + LEFT", hl.dsp.group.prev(), { description = "Move grouped window focus left" })
hl.bind("SUPER + CTRL + RIGHT", hl.dsp.group.next(), { description = "Move grouped window focus right" })

-- Scroll through a set of grouped windows with SUPER + ALT + scroll
hl.bind("SUPER + ALT + mouse_down", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind("SUPER + ALT + mouse_up", hl.dsp.group.prev(), { description = "Previous window in group" })

-- Activate window in a group by number
hl.bind("SUPER + ALT + code:10", hl.dsp.group.active({ index = 1 }), { description = "Switch to group window 1" })
hl.bind("SUPER + ALT + code:11", hl.dsp.group.active({ index = 2 }), { description = "Switch to group window 2" })
hl.bind("SUPER + ALT + code:12", hl.dsp.group.active({ index = 3 }), { description = "Switch to group window 3" })
hl.bind("SUPER + ALT + code:13", hl.dsp.group.active({ index = 4 }), { description = "Switch to group window 4" })
hl.bind("SUPER + ALT + code:14", hl.dsp.group.active({ index = 5 }), { description = "Switch to group window 5" })

-- Cycle monitor scaling with SUPER + /
hl.bind("SUPER + code:61", hl.dsp.exec_cmd("sys-monitor scaling"), { description = "Cycle monitor scaling" })
hl.bind("SUPER + ALT + code:61", hl.dsp.exec_cmd("sys-monitor scaling --reverse"), { description = "Cycle monitor scaling backwards" })
