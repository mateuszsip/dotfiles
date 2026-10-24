-- Menus, toggles, captures and control panels.
-- Migrated from base/bindings/utilities.conf

-- Menus
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("sys-launch apps"), { description = "Launch apps" })
hl.bind("SUPER + CTRL + E", hl.dsp.exec_cmd("sys-launch emoji"), { description = "Emoji picker" })
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd("sys-menu capture"), { description = "Capture menu" })
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("sys-menu toggle"), { description = "Toggle menu" })
hl.bind("SUPER + CTRL + H", hl.dsp.exec_cmd("sys-menu hardware"), { description = "Hardware menu" })
hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("sys-menu"), { description = "Menu" })
hl.bind("SUPER + SHIFT + code:201", hl.dsp.exec_cmd("sys-menu"), { description = "Menu" })
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("sys-menu system"), { description = "System menu" })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("sys-menu system"), { locked = true, description = "Power menu" })
hl.bind("SUPER + K", hl.dsp.exec_cmd("sys-menu keybindings"), { description = "Show key bindings" })
hl.bind("XF86Calculator", hl.dsp.exec_cmd("gnome-calculator"), { description = "Calculator" })

-- Aesthetics
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("sys-toggle-waybar"), { description = "Toggle top bar" })
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("sys-menu background"), { description = "Theme background menu" })
hl.bind("SUPER + SHIFT + CTRL + SPACE", hl.dsp.exec_cmd("sys-menu theme"), { description = "Theme menu" })
hl.bind("SUPER + BACKSPACE", hl.dsp.exec_cmd("sys-window transparency"), { description = "Toggle window transparency" })
hl.bind("SUPER + SHIFT + BACKSPACE", hl.dsp.exec_cmd("sys-window gaps"), { description = "Toggle window gaps" })
hl.bind("SUPER + CTRL + BACKSPACE", hl.dsp.exec_cmd("sys-window square-aspect"), { description = "Toggle single-window square aspect" })

-- Notifications
hl.bind("SUPER + COMMA", hl.dsp.exec_cmd("makoctl dismiss"), { description = "Dismiss last notification" })
hl.bind("SUPER + SHIFT + COMMA", hl.dsp.exec_cmd("makoctl dismiss --all"), { description = "Dismiss all notifications" })
hl.bind("SUPER + CTRL + COMMA", hl.dsp.exec_cmd("sys-toggle-notifications"), { description = "Toggle silencing notifications" })
hl.bind("SUPER + ALT + COMMA", hl.dsp.exec_cmd("makoctl invoke"), { description = "Invoke last notification" })
hl.bind("SUPER + SHIFT + ALT + COMMA", hl.dsp.exec_cmd("makoctl restore"), { description = "Restore last notification" })

-- Toggles
hl.bind("SUPER + CTRL + I", hl.dsp.exec_cmd("sys-toggle-idle"), { description = "Toggle locking on idle" })
hl.bind("SUPER + CTRL + N", hl.dsp.exec_cmd("sys-toggle-nightlight"), { description = "Toggle nightlight" })
hl.bind("SUPER + CTRL + DELETE", hl.dsp.exec_cmd("sys-monitor internal toggle"), { description = "Toggle laptop display" })
hl.bind("SUPER + CTRL + ALT + DELETE", hl.dsp.exec_cmd("sys-monitor mirror toggle"), { description = "Toggle laptop display mirroring" })
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("sys-monitor external && sys-monitor internal off"), { locked = true, description = "Lid closed" })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("sys-monitor internal on"), { locked = true, description = "Lid opened" })

-- Captures
hl.bind("PRINT", hl.dsp.exec_cmd("sys-screenshot"), { description = "Screenshot" })
hl.bind("ALT + PRINT", hl.dsp.exec_cmd("sys-menu screenrecord"), { description = "Screenrecording" })
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"), { description = "Color picker" })
hl.bind("SUPER + CTRL + PRINT", hl.dsp.exec_cmd("sys-ocr"), { description = "Extract text (OCR) from screenshot" })

-- File sharing
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("sys-menu share"), { description = "Share" })

-- Transcoding: dropped with the omarchy layer (omarchy-transcode), the
-- SUPER CTRL + . binding is gone too.

-- Reminders
hl.bind("SUPER + CTRL + R", hl.dsp.exec_cmd("sys-menu reminder-set"), { description = "Set reminder" })
hl.bind("SUPER + CTRL + ALT + R", hl.dsp.exec_cmd("sys-reminder show"), { description = "Show reminders" })
hl.bind("SUPER + SHIFT + CTRL + R", hl.dsp.exec_cmd("sys-reminder clear"), { description = "Clear reminders" })

-- Waybar-less information
hl.bind("SUPER + CTRL + ALT + T", hl.dsp.exec_cmd('notify-send -u low "    $(date +"%A %H:%M  ·  %d %B %Y  ·  Week %V")"'), { description = "Show time" })
hl.bind("SUPER + CTRL + ALT + B", hl.dsp.exec_cmd('notify-send -u low "$(sys-battery-status)"'), { description = "Show battery remaining" })
hl.bind("SUPER + CTRL + ALT + W", hl.dsp.exec_cmd('notify-send -u low "$(sys-weather-status)"'), { description = "Show weather" })

-- Control panels
hl.bind("SUPER + CTRL + A", hl.dsp.exec_cmd("sys-launch audio"), { description = "Audio controls" })
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("sys-launch bluetooth"), { description = "Bluetooth controls" })
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("sys-launch wifi"), { description = "Wifi controls" })
hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("sys-launch tui btop"), { description = "Activity" })

-- Dictation
hl.bind("SUPER + CTRL + X", hl.dsp.exec_cmd("voxtype record toggle"), { description = "Toggle dictation" })

hl.bind("F9", hl.dsp.exec_cmd("voxtype record start"), { description = "Start dictation (push-to-talk)" })
hl.bind("F9", hl.dsp.exec_cmd("voxtype record stop"), { release = true, description = "Stop dictation (push-to-talk)" })

-- Zoom. These are Lua functions rather than shell commands: the old form shelled
-- out to `hyprctl keyword`, which the Lua config manager rejects.
hl.bind("SUPER + CTRL + Z", function()
  local current = hl.get_config("cursor.zoom_factor")
  hl.config({ cursor = { zoom_factor = (type(current) == "number" and current or 1) + 1 } })
end, { description = "Zoom in" })

hl.bind("SUPER + CTRL + ALT + Z", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end, { description = "Reset zoom" })

-- Lock system
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("sys-lock"), { description = "Lock system" })
