-- Per-workspace layout rules.
-- Reference: https://wiki.hypr.land/configuring/core/rules/workspace-rules/
--
-- Workspace 3 uses the scrolling layout: windows sit as columns on an
-- infinite horizontal tape instead of splitting the screen. Everything
-- else keeps the dwindle default from base/looknfeel.lua.
--
-- SUPER + L (sys-workspace-layout) still toggles the focused workspace
-- at runtime; that rule wins until the workspace is recreated.

hl.workspace_rule({ workspace = "3", layout = "scrolling" })
