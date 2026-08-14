-- Status ordering for atlas.nvim Jira issue lists — "closest to done" first.
--
-- atlas exposes no sort option: it renders issues in exactly the order the
-- provider returned them (`build_issue_tree` appends roots in input order and
-- nothing calls `table.sort` on the list). JQL can't express this either —
-- `ORDER BY statusCategory` only has three buckets, and the views filter
-- `statusCategory != Done`, which collapses it to two; `ORDER BY status` sorts
-- by Jira's internal status sequence, not by board-column order.
--
-- So the ordering is applied client-side, keyed on the status *name*. Higher
-- weight = closer to done. Unknown statuses fall back to their statusCategory,
-- so a status added to the workflow later still lands somewhere sane rather
-- than jumping to the top.
--
-- Wired in from lua/plugins/atlas.lua's `config`, which wraps
-- `atlas.issues.ui.main.helper.build_issue_tree` with `M.wrap_build_issue_tree`.

local M = {}

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

-- Order the list by status (closest to done first). `build_issue_tree` is
-- the last thing to touch root order before rendering, and every refresh
-- path in the issues controller goes through it, so wrapping it covers
-- views, bookmarks and JQL searches alike. Children are left in their
-- provider order — subtasks stay grouped under their parent.
function M.wrap_build_issue_tree()
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
function M.disable_relationships_for_flat_views()
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
end

return M
