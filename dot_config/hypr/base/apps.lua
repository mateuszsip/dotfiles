-- App-specific window rules, one module per application.
-- TEMP(hyprlua) phase 4: list filled from base/apps.conf.
--
-- Order matters: these run before the default-opacity rule in base/windows.lua.
local modules = {}

for _, name in ipairs(modules) do
  require("base.apps." .. name)
end
