-- atlas.nvim: PR browsing, diff review, and search across GitHub + LENDABLE Jira.
-- GitHub auth reuses the `gh` CLI, so no tokens here.
-- PR lifecycle actions (approve/close/merge/draft) are not built into atlas,
-- so they are wired as `pulls.custom_actions` that shell out to `gh` and are
-- reachable from the action menu (default `A`).

-- Synchronously resolve the "owner/repo" of the current working directory.
-- Returns nil and notifies on failure. Uses `gh repo view` so it honours the
-- same auth as atlas itself; falls back to parsing `git remote get-url origin`
-- when `gh` is unavailable or the cwd is not a GitHub repo.
local function current_repo()
  local out = vim.fn.system({ "gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner" })
  if vim.v.shell_error == 0 then
    local repo = vim.trim(out)
    if repo ~= "" then
      return repo
    end
  end
  out = vim.fn.system({ "git", "remote", "get-url", "origin" })
  if vim.v.shell_error == 0 then
    local url = vim.trim(out)
    -- ssh:  git@github.com:owner/repo.git
    -- https: https://github.com/owner/repo.git
    local owner_repo = url:match("github%.com[:/]([^/]+/[^/%s]+)%.git") or url:match("github%.com[:/]([^/]+/[^/%s]+)$")
    if owner_repo then
      return owner_repo
    end
  end
  vim.notify("Not in a GitHub repo (no origin remote / gh auth)", vim.log.levels.WARN)
  return nil
end

-- Open the atlas pulls panel scoped to the current repo with the given query
-- suffix (e.g. "is:open author:@me"). The repo: qualifier is prepended.
local function atlas_pulls_repo(query_suffix)
  local repo = current_repo()
  if not repo then
    return
  end
  local query = "is:pr repo:" .. repo .. (query_suffix and (" " .. query_suffix) or "")
  require("atlas").open("pulls", "github", {
    initial_view = { name = "Current repo", layout = "compact", search = query },
  })
end

-- Open the atlas GitHub search prompt prefilled with `is:pr repo:<current>`.
local function atlas_search_repo()
  local repo = current_repo()
  if not repo then
    return
  end
  require("atlas.pulls.providers.github.completion.search").open("is:pr repo:" .. repo .. " ")
end

local function gh_pr(pr, ctx, sub, args, done)
  -- Run `gh pr <sub> <num> <args...>` for the PR. Prefer the local checkout
  -- (ctx.repo_path) when present so `gh` infers the repo; otherwise fall back
  -- to --repo <owner/repo> derived from the PR object.
  local repo = pr.repository and pr.repository.nameWithOwner or pr.repo or pr.repository_full_name
  local cmd = vim.list_extend({ "gh", "pr", sub, tostring(pr.number) }, args or {})
  if not ctx.repo_path then
    if not repo then
      done(false, "No repo path or repository name to target this PR")
      return
    end
    table.insert(cmd, "--repo")
    table.insert(cmd, repo)
  end
  vim.system(cmd, { cwd = ctx.repo_path, text = true }, function(res)
    vim.schedule(function()
      local msg = (res.code == 0) and res.stdout or res.stderr
      if res.code == 0 then
        done(true, (msg ~= "" and msg) or nil)
      else
        done(false, msg or ("gh " .. sub .. " failed (code " .. tostring(res.code) .. ")"))
      end
    end)
  end)
end

-- ---------------------------------------------------------------------------
-- Theme-adaptive highlights
--
-- atlas ships a hardcoded Catppuccin-dark palette and re-applies it from
-- `atlas.ui.shared.highlights.setup()` (plus the per-domain and per-provider
-- highlight modules) on *every* panel open — so plain `nvim_set_hl` calls made
-- at plugin-init time are clobbered the moment the UI opens. We therefore
-- (a) derive the palette from the active colorscheme rather than hardcoding
-- one, and (b) chain our overrides onto those `setup()` functions in `config`
-- below so ours always runs last.
--
-- Every colour is pushed to a WCAG contrast ratio against the surface it sits
-- on (4.5:1), so this reads on flexoki-light here and on whatever omarchy
-- picks on Linux.
-- ---------------------------------------------------------------------------

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

local function apply_atlas_highlights()
  local ok, err = pcall(function()
    for name, spec in pairs(atlas_hl_groups()) do
      vim.api.nvim_set_hl(0, name, spec)
    end
  end)
  if not ok then
    vim.notify_once("atlas.nvim highlights failed: " .. tostring(err), vim.log.levels.WARN)
  end
end

-- ---------------------------------------------------------------------------
-- Status ordering — "closest to done" first
--
-- atlas exposes no sort option: it renders issues in exactly the order the
-- provider returned them (`build_issue_tree` appends roots in input order and
-- nothing calls `table.sort` on the list). JQL can't express this either —
-- `ORDER BY statusCategory` only has three buckets, and the views below filter
-- `statusCategory != Done`, which collapses it to two; `ORDER BY status` sorts
-- by Jira's internal status sequence, not by board-column order.
--
-- So the ordering is applied client-side, keyed on the status *name*. Higher
-- weight = closer to done. Unknown statuses fall back to their statusCategory,
-- so a status added to the workflow later still lands somewhere sane rather
-- than jumping to the top.
-- ---------------------------------------------------------------------------

-- Mirrors the CARD board columns, reversed: To Do → Blocked → In Progress →
-- Review → QA → Done reads left-to-right on the board, so the weights below
-- run the other way. Note Blocked ranks above To Do but below In Progress,
-- matching where the column actually sits on the board.
--
-- These are *status* names, which are not the board's column labels: the
-- REVIEW column is the status "Awaiting review" and QA is "Needs QA". CARD has
-- no "Done" status at all — its Done column is "Closed". Verified against the
-- project workflow, not guessed from the column headers.
local status_rank = {
  ["closed"] = 100,
  ["done"] = 100, -- not used by CARD; kept for other projects' workflows.
  ["needs qa"] = 80,
  ["awaiting review"] = 70,
  ["in progress"] = 50,
  ["blocked"] = 40,
  -- All of the below are To Do category, so only the name separates them.
  -- Ordered by how refined the ticket is; the board collapses them into one
  -- TO DO column, so this ordering is a judgement call — reorder at will.
  ["to do"] = 20,
  ["signed off"] = 16,
  ["triage"] = 12,
  ["refinement"] = 8,
  ["pending"] = 5,
}

-- Fallback when the status name is not in the table above.
local category_rank = { ["done"] = 100, ["in progress"] = 50, ["to do"] = 10 }

---@param issue Issue
---@return number
local function status_weight(issue)
  local status = tostring((issue and issue.status) or ""):lower()
  local rank = status_rank[status]
  if rank then
    return rank
  end
  local category = tostring((issue and issue.status_category) or ""):lower()
  return category_rank[category] or 0
end

-- Render every issue as its own row, ignoring parent/child nesting.
--
-- `build_issue_tree` pulls any issue whose parent is also in the result set out
-- of the top level and nests it under that parent, which fights a status
-- ordering: a Needs QA subtask ends up hidden under a To Do epic instead of
-- sorting to the top. Views marked `flatten = true` opt out of the nesting.
---@param issues Issue[]
---@return IssuesGroup[]
local function flat_groups(issues)
  local groups = {}
  for _, issue in ipairs(issues or {}) do
    if type(issue) == "table" then
      table.insert(groups, { issue = issue, children = {} })
    end
  end
  return groups
end

-- Which view is about to be rendered. `current_view` is assigned immediately
-- before every `build_issue_tree` call in the issues controller (including the
-- bookmark and JQL-search paths), so it is the reliable signal here —
-- `active_view` lags behind on those paths.
---@return boolean
local function current_view_wants_flat()
  local ok, issues_state = pcall(require, "atlas.issues.state")
  if not ok or type(issues_state) ~= "table" then
    return false
  end
  ---@type table
  local view = issues_state.current_view or issues_state.active_view or {}
  return view.flatten == true
end

-- Sort root issues by status, most-progressed first. `table.sort` is not
-- stable, so the incoming position is recorded and used as the tie-break —
-- that keeps each view's JQL `ORDER BY` as the within-status ordering.
local function sort_groups_by_status(groups)
  -- Only Jira issues carry a status_category (the GitHub mapper sets it to nil
  -- and reports just Open/Closed). Without this guard the table above would
  -- sort closed GitHub issues to the top of every `AtlasSearch github` result.
  local is_jira = false
  for _, group in ipairs(groups) do
    if group.issue and group.issue.status_category then
      is_jira = true
      break
    end
  end
  if not is_jira then
    return groups
  end

  local position = {}
  for i, group in ipairs(groups) do
    position[group] = i
  end
  table.sort(groups, function(a, b)
    local wa, wb = status_weight(a.issue), status_weight(b.issue)
    if wa ~= wb then
      return wa > wb
    end
    return position[a] < position[b]
  end)
  return groups
end

-- ---------------------------------------------------------------------------
-- Views
--
-- Defined up here so the keymaps can open a panel directly on a given tab:
-- `atlas.open()` takes an `initial_view`, and the tab bar marks the active tab
-- by matching `key`/`name` — so handing it one of these tables lands on that
-- tab with no follow-up keypress.
-- ---------------------------------------------------------------------------

local github_pull_views = {
  { name = "My open PRs", key = "1", layout = "plain", search = "is:pr is:open author:@me sort:updated-desc" },
  { name = "Review queue", key = "2", layout = "compact", search = "is:pr is:open review-requested:@me" },
  { name = "All my PRs", key = "3", layout = "plain", search = "is:pr author:@me sort:updated-desc" },
  { name = "Mentioned", key = "4", layout = "compact", search = "is:pr is:open mentions:@me" },
  { name = "Recently merged", key = "5", layout = "plain", search = "is:pr is:merged author:@me sort:updated-desc" },
}

local github_issue_views = {
  { name = "Assigned", key = "1", layout = "plain", search = "assignee:@me is:open" },
  { name = "Created", key = "2", layout = "compact", search = "author:@me is:open" },
  { name = "Mentions", key = "3", layout = "plain", search = "mentions:@me is:open" },
}

local jira_views = {
  {
    name = "My tasks",
    key = "1",
    layout = "plain",
    jql = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
  },
  {
    name = "My board tasks",
    key = "2",
    layout = "compact",
    jql = "project = CARD AND assignee = currentUser() AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done ORDER BY created DESC",
  },
  {
    name = "Active sprint",
    key = "3",
    layout = "plain",
    -- Flat list: subtasks stand on their own rather than nesting under their
    -- parent, so the status ordering above applies to every row.
    flatten = true,
    jql = "project = CARD AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done AND assignee is not EMPTY ORDER BY created DESC",
  },
  {
    name = "All platform",
    key = "4",
    layout = "compact",
    jql = "project = CARD AND labels in (Platform, DevOps, Scalability, Technical) ORDER BY created DESC",
  },
  { name = "All CARD", key = "5", layout = "plain", jql = "project = CARD ORDER BY created DESC" },
}

---Look a view up by its `name`, so keymaps don't depend on list order.
---@param views table[]
---@param name string
local function view(views, name)
  for _, v in ipairs(views) do
    if v.name == name then
      return v
    end
  end
  error("atlas: no view named " .. name)
end

---Open a panel straight onto `view_name` — no number key needed.
local function open_view(domain, provider, views, view_name)
  local target = view(views, view_name)
  return function()
    require("atlas").open(domain, provider, { initial_view = target })
  end
end

return {
  "emrearmagan/atlas.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  opts = {
    pulls = {
      diff = {
        open_cmd = "AtlasDiff",
        layout = "inline",
        compact = true,
        explorer = { grouped = true, show_commits = true, width = 40 },
      },
      -- AtlasDiff resolves owner/repo → local checkout via this map. Without it
      -- you'll see "no repo_paths mapping for '<owner>/<repo>'". The wildcard
      -- form maps everything under <root>; explicit entries always win.
      repo_config = {
        paths = {
          ["mateuszsip/*"] = vim.env.ATLAS_REPOS_ROOT and (vim.env.ATLAS_REPOS_ROOT .. "/prv/*") or "~/dev/prv/*",
          ["lendable/*"] = vim.env.ATLAS_REPOS_ROOT and (vim.env.ATLAS_REPOS_ROOT .. "/work/lendable/*")
            or "~/dev/work/lendable/*",
          ["Lendable/*"] = vim.env.ATLAS_REPOS_ROOT and (vim.env.ATLAS_REPOS_ROOT .. "/work/lendable/*")
            or "~/dev/work/lendable/*",
        },
      },
      custom_actions = {
        {
          id = "approve_pr",
          label = "Approve PR",
          confirmation = true,
          run = function(pr, ctx, done)
            gh_pr(pr, ctx, "review", { "--approve" }, done)
          end,
        },
        {
          id = "close_pr",
          label = "Close PR",
          confirmation = true,
          run = function(pr, ctx, done)
            gh_pr(pr, ctx, "close", {}, done)
          end,
        },
        {
          id = "merge_pr",
          label = "Merge PR (squash)",
          confirmation = true,
          run = function(pr, ctx, done)
            gh_pr(pr, ctx, "merge", { "--squash" }, done)
          end,
        },
        {
          id = "toggle_draft",
          label = "Toggle draft / ready",
          confirmation = true,
          run = function(pr, ctx, done)
            local repo = pr.repository and pr.repository.nameWithOwner or pr.repo or pr.repository_full_name
            local view_cmd = vim.list_extend(
              { "gh", "pr", "view", tostring(pr.number), "--json", "isDraft", "-q", ".isDraft" },
              repo and { "--repo", repo } or {}
            )
            vim.system(view_cmd, { cwd = ctx.repo_path, text = true }, function(res)
              vim.schedule(function()
                if res.code ~= 0 then
                  done(false, res.stderr or "gh pr view failed")
                  return
                end
                local is_draft = res.stdout:match("^true") ~= nil
                gh_pr(pr, ctx, "ready", is_draft and {} or { "--undo" }, done)
              end)
            end)
          end,
        },
      },
      providers = {
        github = {
          cache_ttl = 300,
          views = github_pull_views,
        },
      },
    },
    issues = {
      max_results = 200,
      with_relationships = true,
      providers = {
        github = {
          cache_ttl = 300,
          views = github_issue_views,
        },
        jira = {
          base_url = vim.env.LENDABLE_JIRA_BASE_URL or "https://lendable.atlassian.net",
          email = vim.env.LENDABLE_JIRA_EMAIL or "",
          token = vim.env.LENDABLE_JIRA_API_TOKEN or "",
          auth_method = "basic",
          api_type = "cloud",
          cache_ttl = 300,
          project_config = {
            -- Field holding the T-shirt size estimate on CARD project.
            CARD = {
              customfield_11091 = {
                name = "T-shirt size",
                hl_group = "AtlasLogInfo",
              },
            },
          },
          views = jira_views,
          bookmarks = {
            items = {
              ["Backlog"] = "project = CARD AND statusCategory != Done AND (sprint IS EMPTY OR sprint NOT IN openSprints()) ORDER BY Rank ASC",
              ["Next sprint"] = "project = CARD AND sprint in futureSprints() ORDER BY Rank ASC",
              ["My open"] = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
              ["Platform blocked"] = "project = CARD AND labels in (Platform, DevOps, Scalability, Technical) AND status = Blocked ORDER BY updated DESC",
            },
          },
        },
      },
    },
  },
  keys = {
    -- <leader>g* — search/PR/jira binds (replaces LazyVim octo extra + user's octo.lua).
    { "<leader>gp", "<cmd>AtlasSearch github<CR>", desc = "Search PRs/issues (Atlas)" },
    { "<leader>gi", "<cmd>AtlasIssues github<CR>", desc = "List GitHub Issues (Atlas)" },
    { "<leader>gI", "<cmd>AtlasSearch github<CR>", desc = "Search GitHub Issues (Atlas)" },
    -- `gr` (Octo repo list) has no atlas equivalent — opening the panel shows repos.
    { "<leader>gS", "<cmd>AtlasSearch github<CR>", desc = "Search (Atlas)" },
    { "<leader>gC", "<cmd>AtlasCreatePR<CR>", desc = "Create PR (Atlas)" },
    {
      "<leader>gD",
      function()
        vim.ui.input({ prompt = "AtlasDiff (URL or base...head): " }, function(input)
          if input and input ~= "" then
            vim.cmd("AtlasDiff " .. input)
          end
        end)
      end,
      desc = "AtlasDiff (review PR/range)",
    },
    { "<leader>gO", "<cmd>AtlasNotes<CR>", desc = "Local review notes (Atlas)" },

    -- Current-repo scoped (mirror old octo binds that used get_remote_name).
    {
      "<leader>gm",
      function()
        atlas_pulls_repo("is:open author:@me")
      end,
      desc = "My open PRs (current repo)",
    },
    {
      "<leader>gM",
      open_view("pulls", "github", github_pull_views, "My open PRs"),
      desc = "My open PRs (all repos)",
    },
    {
      "<leader>gn",
      function()
        atlas_pulls_repo("author:@me")
      end,
      desc = "All my PRs (current repo)",
    },
    {
      "<leader>gN",
      open_view("pulls", "github", github_pull_views, "All my PRs"),
      desc = "All my PRs (all repos)",
    },
    { "<leader>gR", atlas_search_repo, desc = "Search PRs (current repo)" },

    -- Jira (replaces letieu/jira.nvim). No board UI — these open atlas's issue list.
    {
      "<leader>ji",
      function()
        vim.ui.input({ prompt = "Issue key: ", default = "CARD-" }, function(key)
          if key and key ~= "" then
            vim.cmd("AtlasOpen " .. key)
          end
        end)
      end,
      desc = "Jira: View issue (Atlas)",
    },
    { "<leader>jj", open_view("issues", "jira", jira_views, "My tasks"), desc = "Jira: My tasks (Atlas)" },
    { "<leader>jb", open_view("issues", "jira", jira_views, "My board tasks"), desc = "Jira: My board tasks (Atlas)" },
    { "<leader>js", open_view("issues", "jira", jira_views, "Active sprint"), desc = "Jira: Active sprint (Atlas)" },
    { "<leader>je", "<cmd>AtlasIssues jira<CR>", desc = "Jira: Edit issue (press ge in panel)" },
    {
      "<leader>jc",
      function()
        require("atlas.issues.providers.jira.actions").run("create_issue", {}, function(_, err)
          if err then
            vim.notify("Jira create issue failed: " .. tostring(err), vim.log.levels.ERROR)
          end
        end)
      end,
      desc = "Jira: Create issue (Atlas, bypasses provider prompt)",
    },
    -- jira.nvim's auth login/info have no atlas equivalent; checkhealth reports creds.
    { "<leader>jl", "<cmd>checkhealth atlas<CR>", desc = "Atlas: Check Jira/GitHub auth" },
    { "<leader>ja", "<cmd>checkhealth atlas<CR>", desc = "Atlas: Check Jira/GitHub auth" },
  },
  cmd = {
    "AtlasPulls",
    "AtlasIssues",
    "AtlasDiff",
    "AtlasSearch",
    "AtlasCreatePR",
    "AtlasCreateIssue",
    "AtlasNotes",
    "AtlasOpen",
    "AtlasClearCache",
    "AtlasLogs",
  },
  init = function()
    apply_atlas_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_atlas_highlights })
  end,
  config = function(_, opts)
    require("atlas").setup(opts)

    -- atlas re-applies its own hardcoded palette from these modules every time
    -- a panel opens, so chain ours onto the end of each `setup()` — otherwise
    -- the overrides above are silently discarded on the first open.
    for _, name in ipairs({
      "atlas.ui.shared.highlights",
      "atlas.pulls.ui.highlights",
      "atlas.pulls.providers.github.highlights",
      "atlas.issues.providers.github.highlights",
      "atlas.issues.providers.jira.highlights",
    }) do
      local ok, mod = pcall(require, name)
      if ok and type(mod) == "table" and type(mod.setup) == "function" and not mod.__atlas_hl_chained then
        local upstream = mod.setup
        mod.setup = function(...)
          upstream(...)
          apply_atlas_highlights()
        end
        mod.__atlas_hl_chained = true
      end
    end

    apply_atlas_highlights()

    -- Order the list by status (closest to done first). `build_issue_tree` is
    -- the last thing to touch root order before rendering, and every refresh
    -- path in the issues controller goes through it, so wrapping it covers
    -- views, bookmarks and JQL searches alike. Children are left in their
    -- provider order — subtasks stay grouped under their parent.
    local ok, helper = pcall(require, "atlas.issues.ui.main.helper")
    if ok and type(helper) == "table" and type(helper.build_issue_tree) == "function" then
      if not helper.__atlas_status_sort then
        local upstream = helper.build_issue_tree
        helper.build_issue_tree = function(issues, ...)
          if current_view_wants_flat() then
            return sort_groups_by_status(flat_groups(issues))
          end
          return sort_groups_by_status(upstream(issues, ...))
        end
        helper.__atlas_status_sort = true
      end
    else
      vim.notify_once("atlas.nvim: status sort not applied (build_issue_tree missing)", vim.log.levels.WARN)
    end

    -- A flattened view must not pull in parents its own JQL did not match.
    -- `enrich_with_parents` appends those to the result list — useful context
    -- while nesting, but once the tree is flat they become stray top-level
    -- rows, typically a Closed epic that then sorts to the very top of a view
    -- filtering `statusCategory != Done`. `relationships_enabled` honours
    -- `opts.with_relationships`, so switch it off for these views.
    --
    -- This patches the registered capability table rather than the provider's
    -- own `M`, because the module copies the function *value* into
    -- `capabilities.core` at load time — patching `M.fetch_issues` afterwards
    -- would never be seen. `providers.load()` hands out this same table, so
    -- there is no copy in between.
    local ok_jira, jira = pcall(require, "atlas.issues.providers.jira")
    local core = ok_jira and type(jira) == "table" and jira.capabilities and jira.capabilities.core or nil
    if type(core) == "table" and type(core.fetch_issues) == "function" then
      if not core.__atlas_flatten_patched then
        local upstream_fetch = core.fetch_issues
        core.fetch_issues = function(view, opts, on_done)
          if type(view) == "table" and view.flatten then
            opts = vim.tbl_extend("force", opts or {}, { with_relationships = false })
          end
          return upstream_fetch(view, opts, on_done)
        end
        core.__atlas_flatten_patched = true
      end
    else
      vim.notify_once("atlas.nvim: flatten opt-out not applied (jira fetch_issues missing)", vim.log.levels.WARN)
    end
  end,
}
