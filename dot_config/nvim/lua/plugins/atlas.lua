-- atlas.nvim: PR browsing, diff review, and search across GitHub + LENDABLE Jira.
-- GitHub auth reuses the `gh` CLI, so no tokens here.
-- PR lifecycle actions (approve/close/merge/draft) are not built into atlas,
-- so they are wired as `pulls.custom_actions` that shell out to `gh` and are
-- reachable from the action menu (default `A`).
--
-- Supporting modules:
--   lua/utils/atlas_highlights.lua — theme-adaptive highlight palette (WCAG 4.5:1)
--   lua/utils/atlas_sort.lua       — Jira status ordering + flat-view handling

local highlights = require("utils.atlas_highlights")
local sort = require("utils.atlas_sort")

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

-- atlas' PullRequest keeps the PR number in `id` and the slug in
-- `repo_full_name` (atlas/pulls/types.lua, github/api/mapper.lua) — there is no
-- `number` and no `repository` field, and `repo` is the bare name without the
-- owner. Reading those ran `gh pr <sub> nil` and every custom action failed.
local function pr_number(pr)
  return pr.id
end

local function pr_slug(pr)
  return pr.repo_full_name
end

local function gh_pr(pr, ctx, sub, args, done)
  -- Run `gh pr <sub> <num> <args...>` for the PR. Prefer the local checkout
  -- (ctx.repo_path) when present so `gh` infers the repo; otherwise fall back
  -- to --repo <owner/repo> derived from the PR object.
  local repo = pr_slug(pr)
  local number = pr_number(pr)
  if not number then
    done(false, "PR has no number")
    return
  end
  local cmd = vim.list_extend({ "gh", "pr", sub, tostring(number) }, args or {})
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
      -- Lendable repos disable merge commits and rebases (squash only), and
      -- atlas defaults to `--merge` — which fails with "Merge commits are not
      -- allowed on this repository" from the GraphQL mergePullRequest call.
      default_merge_method = "squash",
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
    highlights.apply()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = highlights.apply })

    -- The PR/issue panels flip their scratch buffer to `filetype=markdown` so
    -- render-markdown draws the body — which trips LazyVim's `wrap_spell`
    -- autocmd and turns `spell` on. Spell attributes win over the panel's own
    -- extmarks, so SpellCap repaints the "open" state chip yellow-on-green
    -- (1.5:1 instead of 5:1) and SpellBad red-underlines every SHA, branch and
    -- product name in the header. Nothing in a read-only panel is worth
    -- spell-checking, so switch it off for atlas' own scratch buffers — the
    -- comment/review editor popups are real markdown buffers and keep it.
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("atlas_nospell", { clear = true }),
      callback = function(ev)
        if vim.bo[ev.buf].buftype ~= "nofile" then
          return
        end
        if not vim.fs.basename(vim.api.nvim_buf_get_name(ev.buf)):match("^Atlas") then
          return
        end
        -- Deferred because LazyVim's FileType handler may be registered after
        -- ours; `spell` is window-local, so clear it on every window showing
        -- the buffer rather than only the current one.
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(ev.buf) then
            return
          end
          for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
            vim.wo[win].spell = false
          end
        end)
      end,
    })
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
          highlights.apply()
        end
        mod.__atlas_hl_chained = true
      end
    end

    highlights.apply()

    sort.wrap_build_issue_tree()
    sort.disable_relationships_for_flat_views()
  end,
}
