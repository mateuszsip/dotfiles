-- Theme-adaptive highlights for atlas.nvim.
--
-- atlas ships a hardcoded Catppuccin-dark palette and re-applies it from
-- `atlas.ui.shared.highlights.setup()` (plus the per-domain and per-provider
-- highlight modules) on *every* panel open — so plain `nvim_set_hl` calls made
-- at plugin-init time are clobbered the moment the UI opens. We therefore
-- (a) derive the palette from the active colorscheme rather than hardcoding
-- one, and (b) chain our overrides onto those `setup()` functions in the
-- plugin's `config` (see lua/plugins/atlas.lua) so ours always runs last.
--
-- Every colour is pushed to a WCAG contrast ratio against the surface it sits
-- on (4.5:1), so this reads on flexoki-light here and on whatever omarchy
-- picks on Linux.

local M = {}

---@param name string highlight group
---@param attr "fg"|"bg"
---@return string|nil hex
local function get_hl(name, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if not ok or type(hl) ~= "table" or type(hl[attr]) ~= "number" then
    return nil
  end
  return string.format("#%06X", hl[attr])
end

local function hex2rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function rgb2hex(r, g, b)
  local function byte(v)
    return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5)
  end
  return string.format("#%02X%02X%02X", byte(r), byte(g), byte(b))
end

local function rgb2hsl(hex)
  local r, g, b = hex2rgb(hex)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local l = (max + min) / 2
  if max == min then
    return 0, 0, l
  end
  local d = max - min
  local s = l > 0.5 and d / (2 - max - min) or d / (max + min)
  local h
  if max == r then
    h = (g - b) / d + (g < b and 6 or 0)
  elseif max == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  return h / 6, s, l
end

local function hsl2hex(h, s, l)
  if s == 0 then
    return rgb2hex(l, l, l)
  end
  local function channel(p, q, t)
    t = t % 1
    if t < 1 / 6 then
      return p + (q - p) * 6 * t
    elseif t < 1 / 2 then
      return q
    elseif t < 2 / 3 then
      return p + (q - p) * (2 / 3 - t) * 6
    end
    return p
  end
  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  return rgb2hex(channel(p, q, h + 1 / 3), channel(p, q, h), channel(p, q, h - 1 / 3))
end

-- WCAG 2.1 relative luminance / contrast ratio.
local function luminance(hex)
  local function linear(v)
    return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  local r, g, b = hex2rgb(hex)
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

local function mix(a, b, t)
  local ar, ag, ab = hex2rgb(a)
  local br, bg, bb = hex2rgb(b)
  return rgb2hex(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
end

-- Re-light `hex` (hue and saturation preserved) until it clears `target`
-- contrast against `over`, walking away from that background's luminance.
local function fit(hex, over, target)
  local h, s, l = rgb2hsl(hex)
  local step = luminance(over) < 0.5 and 0.02 or -0.02
  for _ = 1, 50 do
    local candidate = hsl2hex(h, s, l)
    if contrast(candidate, over) >= target then
      return candidate
    end
    l = l + step
    if l > 0.97 or l < 0.03 then
      break
    end
  end
  return hsl2hex(h, s, math.max(0.03, math.min(0.97, l)))
end

-- Same, but for a hue picked by us rather than lifted from the colorscheme.
local function tone(degrees, saturation, over, target)
  return fit(hsl2hex(degrees / 360, saturation, luminance(over) < 0.5 and 0.62 or 0.48), over, target)
end

local function atlas_hl_groups()
  local bg = get_hl("Normal", "bg") or (vim.o.background == "light" and "#FFFFFF" or "#111111")
  local fg = get_hl("Normal", "fg") or (vim.o.background == "light" and "#111111" or "#DDDDDD")
  local dark = luminance(bg) < 0.5

  -- Raised surface for the tab strip, footer and panel headers. Most schemes
  -- give us a usable one; reject it if it is invisible or too loud.
  local surface = get_hl("CursorLine", "bg") or get_hl("StatusLine", "bg")
  if not surface or surface == bg or contrast(surface, bg) > 1.7 then
    surface = mix(bg, fg, dark and 0.12 or 0.08)
  end

  -- Accents are borrowed from the colorscheme, but only when they land near the
  -- hue the role is meant to read as *and* stay clear of the roles already
  -- assigned — otherwise we synthesize the hue at the scheme's own saturation.
  -- Without this, a scheme whose `Keyword` is green (flexoki) collapses "purple"
  -- onto "green" and merged PRs become indistinguishable from open ones.
  local candidates = {
    red = get_hl("DiagnosticError", "fg"),
    yellow = get_hl("DiagnosticWarn", "fg"),
    green = get_hl("DiagnosticOk", "fg") or get_hl("String", "fg"),
    blue = get_hl("DiagnosticInfo", "fg") or get_hl("Function", "fg"),
    purple = get_hl("Keyword", "fg") or get_hl("Statement", "fg"),
    orange = get_hl("Constant", "fg") or get_hl("Number", "fg"),
    cyan = get_hl("DiagnosticHint", "fg") or get_hl("Special", "fg"),
  }
  local hue_of = { red = 8, yellow = 50, green = 105, blue = 220, purple = 290, orange = 30, cyan = 180 }
  local roles = { "red", "yellow", "green", "blue", "purple", "orange", "cyan" }

  local function hue_gap(a, b)
    local d = math.abs(a - b) % 360
    return d > 180 and 360 - d or d
  end

  -- Saturation of the scheme's own accents, so synthesized hues match its mood.
  local saturation, samples = 0, 0
  for _, color in pairs(candidates) do
    local _, s = rgb2hsl(color)
    if s > 0.15 then
      saturation, samples = saturation + s, samples + 1
    end
  end
  saturation = samples > 0 and math.max(0.45, math.min(0.85, saturation / samples)) or 0.6

  local accent, claimed = {}, {}
  for _, role in ipairs(roles) do
    local want = hue_of[role]
    local color, hue = candidates[role], nil
    local keep = false
    if color then
      local h, s = rgb2hsl(color)
      hue = h * 360
      keep = s > 0.15 and hue_gap(hue, want) <= 35
      for _, used in ipairs(claimed) do
        if keep and hue_gap(hue, used) < 22 then
          keep = false
        end
      end
    end
    accent[role] = keep and color or tone(want, saturation, bg, 4.5)
    table.insert(claimed, keep and hue or want)
  end

  local function text(color, over)
    return fit(color, over or bg, 4.5)
  end

  -- Chips carry the surrounding surface colour as ink, so the body has to clear
  -- 4.5:1 against it — which also makes the chip itself pop off the panel.
  local function chip(color)
    local body = fit(color, bg, 4.5)
    return {
      fg = contrast(bg, body) >= contrast(fg, body) and bg or fg,
      bg = body,
      bold = true,
    }
  end

  local muted = text(mix(fg, bg, 0.45))
  local muted_on_surface = fit(mix(fg, surface, 0.4), surface, 4.5)
  local grey = mix(fg, bg, 0.35)
  local header = text(mix(fg, bg, 0.2))
  -- Provider banner / active tab. GitHub's brand is monochrome, so invert.
  local inverse = { fg = bg, bg = fg, bold = true }

  local groups = {
    AtlasText = { fg = fg },
    AtlasBorder = { fg = fit(mix(fg, bg, 0.6), bg, 3) },
    AtlasTabInactive = { fg = muted_on_surface, bg = surface },
    AtlasPanelHeaderBg = { bg = surface },
    AtlasColumnHeader = { fg = header, bold = true },
    AtlasSectionHeader = { fg = header, bold = true, underline = true },

    AtlasTextMuted = { fg = muted },
    AtlasTextMutedItalic = { fg = muted, italic = true },
    AtlasTextMutedStrikethrough = { fg = muted, strikethrough = true },
    AtlasTextPositive = { fg = text(accent.green), bold = true },
    AtlasTextWarning = { fg = text(accent.yellow), bold = true },
    AtlasTextNote = { fg = text(accent.purple), bold = true },

    AtlasLogInfo = { fg = text(accent.blue), bold = true },
    AtlasLogWarn = { fg = text(accent.orange), bold = true },
    AtlasLogError = { fg = text(accent.red), bold = true },

    AtlasFooterBackground = { bg = surface },
    AtlasFooterText = { fg = muted_on_surface, bg = surface },
    AtlasFooterInfo = { fg = text(accent.blue, surface), bg = surface, bold = true },
    AtlasFooterNote = { fg = text(accent.purple, surface), bg = surface, bold = true },
    AtlasFooterWarning = { fg = text(accent.yellow, surface), bg = surface, bold = true },
    AtlasFooterError = { fg = text(accent.red, surface), bg = surface, bold = true },
    AtlasFooterSuccess = { fg = text(accent.green, surface), bg = surface, bold = true },

    AtlasChipActive = chip(accent.blue),

    -- Pull requests.
    AtlasPROpen = { fg = text(accent.green), bold = true },
    AtlasPRMerged = { fg = text(accent.purple), bold = true },
    AtlasPRDeclined = { fg = text(accent.red), bold = true },
    AtlasPRDraft = { fg = muted, bold = true },
    AtlasPROpenChip = chip(accent.green),
    AtlasPRMergedChip = chip(accent.purple),
    AtlasPRDeclinedChip = chip(accent.red),
    AtlasPRDraftChip = chip(grey),
    AtlasPipelineLinkSuccess = { fg = text(accent.green) },
    AtlasPipelineLinkFailed = { fg = text(accent.red) },
    AtlasPipelineLinkInProgress = { fg = text(accent.yellow) },
    AtlasPipelineLinkMuted = { fg = muted },

    -- GitHub pulls.
    AtlasGitHubTheme = inverse,
    AtlasGitHubPROpen = chip(accent.green),
    AtlasGitHubPRMerged = chip(accent.purple),
    AtlasGitHubPRClosed = chip(accent.red),
    AtlasGitHubPRDraft = chip(grey),

    -- GitHub issues.
    AtlasGHIssuesTheme = inverse,
    AtlasGHIssueOpen = { fg = text(accent.green), bold = true },
    AtlasGHIssueClosed = { fg = text(accent.purple), bold = true },
    AtlasGHIssueOpenChip = chip(accent.green),
    AtlasGHIssueClosedChip = chip(accent.purple),
    AtlasGHIssueKey = { fg = text(accent.blue), bold = true },
    AtlasGHIssueChipRepo = chip(accent.blue),

    -- Jira. Upstream's AtlasJiraTheme sets only a dark blue bg and inherits the
    -- Normal fg, which is unreadable on a light scheme — hence a full chip.
    AtlasJiraTheme = chip(accent.blue),
    AtlasJiraKey = { fg = text(accent.blue), bold = true },
    AtlasJiraChipStoryPoints = chip(accent.purple),
    AtlasJiraChipDueDate = chip(accent.yellow),
    AtlasJiraChipParent = chip(accent.blue),
    AtlasProjectKey = { fg = text(accent.cyan), bold = true },
  }

  -- Identity palette: atlas hashes repo names, authors, Jira statuses and issue
  -- types into 11 fixed slots (AtlasDynColor* for text, AtlasDynBgColor* for
  -- chips). Fixed hue order, re-lit per theme. The label text is always printed
  -- next to the colour, so identity is never colour-alone.
  local dyn_hues = { 212, 32, 162, 55, 322, 128, 268, 5, 186, 88, 285 }
  for i, hue in ipairs(dyn_hues) do
    local color = tone(hue, dark and 0.55 or 0.62, bg, 4.5)
    groups[string.format("AtlasDynColor%02d", i)] = { fg = color }
    groups[string.format("AtlasDynBgColor%02d", i)] = {
      fg = contrast(bg, color) >= contrast(fg, color) and bg or fg,
      bg = color,
      bold = true,
    }
  end

  return groups
end

function M.apply()
  local ok, err = pcall(function()
    for name, spec in pairs(atlas_hl_groups()) do
      vim.api.nvim_set_hl(0, name, spec)
    end
  end)
  if not ok then
    vim.notify_once("atlas.nvim highlights failed: " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
