-- Laptop multimedia keys for volume and LCD brightness (with OSD).
-- Migrated from base/bindings/media.conf; that file stays authoritative until phase 7.
--
-- `bindeld` = repeating + locked + description; `bindld` = locked + description.

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("sys-osd --output-volume raise"), { repeating = true, locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("sys-osd --output-volume lower"), { repeating = true, locked = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("sys-osd --output-volume mute-toggle"), { repeating = true, locked = true, description = "Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("sys-audio input-mute"), { repeating = true, locked = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("sys-brightness +5%"), { repeating = true, locked = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sys-brightness 5%-"), { repeating = true, locked = true, description = "Brightness down" })
hl.bind("SHIFT + XF86MonBrightnessUp", hl.dsp.exec_cmd("sys-brightness 100%"), { repeating = true, locked = true, description = "Brightness maximum" })
hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd("sys-brightness 1%"), { repeating = true, locked = true, description = "Brightness minimum" })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("sys-brightness --keyboard up"), { repeating = true, locked = true, description = "Keyboard brightness up" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("sys-brightness --keyboard down"), { repeating = true, locked = true, description = "Keyboard brightness down" })
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd("sys-brightness --keyboard cycle"), { locked = true, description = "Keyboard backlight cycle" })
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("sys-touchpad"), { locked = true, description = "Toggle touchpad" })
hl.bind("XF86TouchpadOn", hl.dsp.exec_cmd("sys-touchpad on"), { locked = true, description = "Enable touchpad" })
hl.bind("XF86TouchpadOff", hl.dsp.exec_cmd("sys-touchpad off"), { locked = true, description = "Disable touchpad" })

-- Precise 1% multimedia adjustments with Alt modifier
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("sys-osd --output-volume +1"), { repeating = true, locked = true, description = "Volume up precise" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd("sys-osd --output-volume -1"), { repeating = true, locked = true, description = "Volume down precise" })
hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd("sys-brightness +1%"), { repeating = true, locked = true, description = "Brightness up precise" })
hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd("sys-brightness 1%-"), { repeating = true, locked = true, description = "Brightness down precise" })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("sys-osd --playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("sys-osd --playerctl play-pause"), { locked = true, description = "Pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("sys-osd --playerctl play-pause"), { locked = true, description = "Play" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("sys-osd --playerctl previous"), { locked = true, description = "Previous track" })

-- Switch audio output with Super + Mute
hl.bind("SUPER + XF86AudioMute", hl.dsp.exec_cmd("sys-audio output-switch"), { locked = true, description = "Switch audio output" })
