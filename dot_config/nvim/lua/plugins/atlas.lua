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
          ["lendable/*"] = vim.env.ATLAS_REPOS_ROOT and (vim.env.ATLAS_REPOS_ROOT .. "/work/lendable/*") or "~/dev/work/lendable/*",
          ["Lendable/*"] = vim.env.ATLAS_REPOS_ROOT and (vim.env.ATLAS_REPOS_ROOT .. "/work/lendable/*") or "~/dev/work/lendable/*",
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
          views = {
            {
              name = "My open PRs",
              key = "1",
              layout = "plain",
              search = "is:pr is:open author:@me sort:updated-desc",
            },
            { name = "Review queue", key = "2", layout = "compact", search = "is:pr is:open review-requested:@me" },
            { name = "All my PRs", key = "3", layout = "plain", search = "is:pr author:@me sort:updated-desc" },
            { name = "Mentioned", key = "4", layout = "compact", search = "is:pr is:open mentions:@me" },
            {
              name = "Recently merged",
              key = "5",
              layout = "plain",
              search = "is:pr is:merged author:@me sort:updated-desc",
            },
          },
        },
      },
    },
    issues = {
      max_results = 200,
      with_relationships = true,
      providers = {
        github = {
          cache_ttl = 300,
          views = {
            { name = "Assigned", key = "1", layout = "plain", search = "assignee:@me is:open" },
            { name = "Created", key = "2", layout = "compact", search = "author:@me is:open" },
            { name = "Mentions", key = "3", layout = "plain", search = "mentions:@me is:open" },
          },
        },
        -- LENDABLE Jira. Credentials exported by
        -- ~/.config/nushell/jira_atlas.nu (Bitwarden-backed, see source).
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
          views = {
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
              jql = "project = CARD AND assignee = currentUser() AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done ORDER BY created DESC, Rank ASC",
            },
            {
              name = "Active sprint",
              key = "3",
              layout = "plain",
              jql = "project = CARD AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done AND assignee is not EMPTY ORDER BY created DESC, Rank ASC",
            },
            {
              name = "All platform",
              key = "4",
              layout = "compact",
              jql = "project = CARD AND labels in (Platform, DevOps, Scalability, Technical) ORDER BY created DESC, Rank ASC",
            },
            {
              name = "All CARD",
              key = "5",
              layout = "plain",
              jql = "project = CARD ORDER BY created DESC, Rank ASC",
            },
          },
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
    { "<leader>gM", "<cmd>AtlasPulls github<CR>", desc = "My open PRs (all repos, press 1)" },
    {
      "<leader>gn",
      function()
        atlas_pulls_repo("author:@me")
      end,
      desc = "All my PRs (current repo)",
    },
    { "<leader>gN", "<cmd>AtlasPulls github<CR>", desc = "All my PRs (all repos, press 3)" },
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
    { "<leader>jj", "<cmd>AtlasIssues jira<CR>", desc = "Jira: Open panels (Atlas)" },
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
    -- Flexoki-light overrides for atlas.nvim. Applied on every colorscheme switch
    -- so they survive theme changes (flexoki ships its own palette at swap time).
    -- Palette: paper #FFFCF0, bg-50 #F2F0E5, bg-100 #E6E4D9, text-100 #100F0D,
    -- text-300 #100F0D/70, text-500 #100F0D/40, line #E6E4D9.
    -- Accents: red #D14D41, green #879A39, blue #4385BE, yellow #D0A215,
    -- orange #DA702C, purple #8B7EC8, cyan #3AA99F, grey #878580.
    local function flexoki_atlas_hl()
      local paper = "#FFFCF0"
      local bg50 = "#F2F0E5"
      local bg100 = "#E6E4D9"
      local text = "#100F0D"
      local text300 = "#5C5A52"
      local text500 = "#878580"
      local line = "#E6E4D9"
      local red, green, blue, yellow, orange, purple, cyan =
        "#D14D41", "#879A39", "#4385BE", "#D0A215", "#DA702C", "#8B7EC8", "#3AA99F"
      local groups = {
        AtlasTabActive = { bg = bg50, fg = text, bold = true },
        AtlasTabInactive = { bg = bg100, fg = text500 },
        AtlasPanelHeaderBg = { bg = bg100 },
        AtlasColumnHeader = { fg = text300, bold = true },
        AtlasSectionHeader = { fg = text300, bold = true, underline = true },
        AtlasBorder = { fg = line },
        AtlasTextMuted = { fg = text500 },
        AtlasTextMutedItalic = { fg = text500, italic = true },
        AtlasTextMutedStrikethrough = { fg = text500, strikethrough = true },
        AtlasTextPositive = { fg = green, bold = true },
        AtlasTextWarning = { fg = yellow, bold = true },
        AtlasLogInfo = { fg = blue, bold = true },
        AtlasLogWarn = { fg = orange, bold = true },
        AtlasLogError = { fg = red, bold = true },
        AtlasFooterBackground = { bg = bg50 },
        AtlasFooterText = { fg = text500 },
        AtlasChipActive = { fg = paper, bg = blue, bold = true },
        AtlasChipPending = { fg = paper, bg = yellow, bold = true },
        AtlasChipError = { fg = paper, bg = red, bold = true },
        AtlasChipSuccess = { fg = paper, bg = green, bold = true },
        AtlasChipReviewRequested = { fg = paper, bg = purple, bold = true },
        AtlasChipChangesRequested = { fg = paper, bg = orange, bold = true },
        AtlasChipApproved = { fg = paper, bg = green, bold = true },
        AtlasChipMerged = { fg = paper, bg = purple, bold = true },
        AtlasChipClosed = { fg = paper, bg = red, bold = true },
        AtlasChipDraft = { fg = paper, bg = text500, bold = true },
        AtlasChipOpen = { fg = text, bg = bg100, bold = true },
      }
      for name, spec in pairs(groups) do
        vim.api.nvim_set_hl(0, name, spec)
      end
    end
    flexoki_atlas_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = flexoki_atlas_hl })
  end,
}
