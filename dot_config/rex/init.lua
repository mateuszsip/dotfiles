-- Rex configuration (~/.config/rex/init.lua), read by the server and every
-- Rex client, including rexia. Bindings here sit ABOVE rexia's defaults, so
-- a binding only needs to be listed when it should replace a default.
--
-- rexia's relevant defaults (no need to rebind these):
--   ctrl+shift+k      Change Session… (picker — no sidebar needed)
--   ctrl+alt+shift+down/up   next / previous session
--   ctrl+shift+b      toggle the sidebar
--   ctrl+tab / ctrl+shift+tab, ctrl+pagedown / ctrl+pageup   next / previous tab
--   alt+1…alt+9       go to tab N
--   ctrl+shift+t      new tab
--   ctrl+alt+w       close tab
--   ctrl+shift+s      cycle tab style (above / left / right)
--   ctrl+shift+p      command palette (searches all actions)
--
-- Overrides: these sit above rexia's defaults, so they win. Letters carry
-- three levels — k/j are down (next), l/; are up (previous) — and the
-- arrows stay as a second way to cycle sessions and hosts:
--   ctrl+alt+k / l          next / previous tab
--   ctrl+alt+shift+k / l    next / previous session
--   ctrl+alt+shift+j / ;    next / previous host
--   ctrl+alt+down / up      next / previous session
--   ctrl+alt+shift+down / up  next / previous host
-- Costs: ctrl+alt+arrows and k/l leave pane focus (vertical splits stay
-- reachable with ctrl+shift+space and the mouse).
rex.bind("ctrl+alt+k", "client.tab.next")
rex.bind("ctrl+alt+l", "client.tab.previous")
rex.bind("ctrl+alt+shift+k", "session.next")
rex.bind("ctrl+alt+shift+l", "session.previous")
rex.bind("ctrl+alt+shift+j", "client.host.next")
rex.bind("ctrl+alt+shift+;", "client.host.previous")
rex.bind("ctrl+alt+down", "session.next")
rex.bind("ctrl+alt+up", "session.previous")
rex.bind("ctrl+alt+shift+down", "client.host.next")
rex.bind("ctrl+alt+shift+up", "client.host.previous")
-- rex.bind("ctrl+shift+w", "client.tab.close")   -- (default closes the window)
-- rex.unbind("ctrl+tab")                          -- free a default key
