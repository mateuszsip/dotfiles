-- Monitors. Hand-owned: nwg-displays is retired (it regenerates hyprlang, which
-- the Lua manager would never read). Edit the values here and commit.
--
-- Migrated from monitors.conf; that file stays authoritative until phase 7.

hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60.01",
  position = "0x812",
  scale = 1.33,
})

hl.monitor({
  output = "desc:Xiaomi Corporation Mi Monitor 5744900052948",
  mode = "2560x1440@120.0",
  position = "auto",
  scale = 1.33,
  bitdepth = 10,
})

-- Internal panel on/off. A Lua function is the dispatcher, so no `hyprctl` and
-- no shell: the action is the config call itself.
hl.bind("SUPER + SHIFT + ALT + N", function()
  hl.monitor({ output = "eDP-1", disabled = true })
end, { description = "Disable internal screen" })

hl.bind("SUPER + SHIFT + ALT + M", function()
  hl.monitor({ output = "eDP-1", mode = "1920x1080@60.01", position = "0x812", scale = 1.33 })
end, { description = "Enable internal screen" })

-- >>> managed by a-la-carchy power-profile
hl.on("hyprland.start", function()
  hl.exec_cmd("/home/sip/.config/hypr/scripts/power-profile-default.sh")
end)
-- <<< managed by a-la-carchy power-profile
