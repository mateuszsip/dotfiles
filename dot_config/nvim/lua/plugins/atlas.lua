-- atlas.nvim: PR browsing, diff review, and search across GitHub + LENDABLE Jira.
-- GitHub auth reuses the `gh` CLI, so no tokens here.
-- PR lifecycle actions come from atlas' own action menu (default `A`): Approve,
-- Request changes, Merge, Decline (= close), Convert to draft / Mark as ready.
-- They are state-gated and refresh the panel, unlike `pulls.custom_actions`,
-- which cannot report a state change and silently ignore `confirmation`.
--
-- Supporting modules:
--   lua/utils/atlas_highlights.lua — theme-adaptive highlight palette (WCAG 4.5:1)
--   lua/utils/atlas_sort.lua       — Jira status ordering, flat views, PR list order
--   lua/utils/atlas_lendable.lua   — Lendable-specific paths (AtlasDiff LSP vendor links)

local highlights = require("utils.atlas_highlights")
local sort = require("utils.atlas_sort")
local lendable = require("utils.atlas_lendable")

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

-- Prompt for a GitHub login and list their PRs (any state), scoped to the
-- current repo or across all repos.
---@param scope "repo"|"all"
local function atlas_pulls_by_author(scope)
  vim.ui.input({ prompt = "PR author (GitHub login): " }, function(author)
    author = author and vim.trim(author):gsub("^@", "")
    if not author or author == "" then
      return
    end
    if scope == "repo" then
      atlas_pulls_repo("author:" .. author)
    else
      require("atlas").open("pulls", "github", {
        initial_view = { name = "Author: " .. author, layout = "compact", search = "is:pr author:" .. author },
      })
    end
  end)
end

-- Multi-select my open PRs and yank their URLs (one per line) to the `+` register.
-- Atlas' own `copy_url` (`Y`) only ever copies the PR under the cursor and
-- overwrites the clipboard, and its PR list has no marking concept — so this
-- goes straight to `gh` for the data and borrows atlas' picker for the UI.
--
-- `atlas.ui.picker` is an internal module (same one atlas uses for its reviewer and
-- label pickers). Depending on it rather than driving snacks directly keeps the
-- `ui.picker = "auto"` preference working.
--
---@param scope "repo"|"all" limit to the cwd repo, or search every repo
local function copy_pr_links(scope)
  local args = {
    "gh",
    "search",
    "prs",
    "--author=@me",
    "--state=open",
    "--limit=100",
    "--archived=false",
    "--json",
    "number,title,url,repository",
  }

  local title = "Copy PR links — all repos"
  if scope == "repo" then
    local repo = current_repo() -- notifies and returns nil when not in a GitHub repo
    if not repo then
      return
    end
    table.insert(args, "--repo=" .. repo)
    title = "Copy PR links — " .. repo
  end

  vim.system(args, { text = true }, function(result)
    -- Back onto the main loop: no vim.* API calls are allowed in the callback.
    vim.schedule(function()
      if result.code ~= 0 then
        local stderr = vim.trim(result.stderr or "")
        vim.notify(
          "gh search prs failed: " .. (stderr ~= "" and stderr or "exit " .. result.code),
          vim.log.levels.ERROR
        )
        return
      end

      local ok, prs = pcall(vim.json.decode, result.stdout)
      if not ok or type(prs) ~= "table" or #prs == 0 then
        vim.notify("No open PRs found", vim.log.levels.WARN)
        return
      end

      require("atlas.ui.picker").multi_select({
        title = title,
        items = prs,
        selected = {},
        -- URL, not number: PR numbers collide across repos in the "all" scope.
        key = function(pr)
          return tostring(pr.url)
        end,
        format_item = function(pr)
          local prefix = "#" .. pr.number
          if scope ~= "repo" then
            prefix = (pr.repository and pr.repository.nameWithOwner or "?") .. prefix
          end
          return string.format("%s  %s", prefix, pr.title or "")
        end,
        on_done = function(selected)
          -- Cancelling calls on_done with the initial `selected` ({}), so an
          -- empty list means "cancelled" or "confirmed nothing". Both leave the
          -- clipboard untouched.
          if not selected or #selected == 0 then
            return
          end
          local urls = {}
          for _, pr in ipairs(selected) do
            urls[#urls + 1] = pr.url
          end
          vim.fn.setreg("+", table.concat(urls, "\n"))
          vim.notify(string.format("Copied %d PR link(s)", #urls))
        end,
      })
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
  {
    name = "My open PRs",
    key = "1",
    layout = "grouped",
    search = "is:pr is:open author:@me sort:updated-desc archived:false",
  },
  {
    name = "Review queue",
    key = "2",
    layout = "compact",
    search = "is:pr is:open review-requested:@me archived:false",
    -- Filtered client-side (utils/atlas_sort.lua): GitHub search can't anchor a
    -- title prefix and drops the punctuation in "chore: [release]".
    exclude_title_prefixes = { "chore: [release]" },
  },
  {
    name = "All my PRs",
    key = "3",
    layout = "grouped",
    -- atlas strips state qualifiers into its open/merged/declined filters and
    -- defaults to open-only when there are none, so spell out all three. Must
    -- match atlas' own form exactly (providers/github/query.lua) to be parsed.
    search = "is:pr author:@me (is:open OR is:merged OR is:closed -is:merged) sort:updated-desc archived:false",
  },
  {
    name = "Mentioned",
    key = "4",
    layout = "compact",
    search = "is:pr is:open mentions:@me archived:false",
    exclude_title_prefixes = { "chore: [release]" },
  },
  {
    name = "Recently merged",
    key = "5",
    layout = "grouped",
    search = "is:pr is:merged author:@me sort:updated-desc archived:false",
  },
}

local github_issue_views = {
  { name = "Assigned", key = "1", layout = "plain", search = "assignee:@me is:open archived:false" },
  { name = "Created", key = "2", layout = "compact", search = "author:@me is:open archived:false" },
  { name = "Mentions", key = "3", layout = "plain", search = "mentions:@me is:open archived:false" },
}

local jira_views = lendable.jira_views

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
    ui = {
      -- Atlas always opens its own tab (hardcoded `tabnew`); listing the panel
      -- at least lets you switch away from and back to it like a normal buffer.
      listed_buffer = true,
    },
    keymaps = {
      ui = {
        -- Match the shifted jkl; layout (see config/keymaps.lua). Atlas binds
        -- `j`=next / `k`=previous buffer-locally, which shadows the global remap:
        -- `k` (Down) moved up, `l` (Up) did nothing, `j` (Left) moved down.
        -- Rebinding frees `j`, so it falls through to the global Left again.
        next_item = "k",
        previous_item = "l",
      },
    },
    pulls = {
      -- Lendable repos disable merge commits and rebases (squash only), and
      -- atlas defaults to `--merge` — which fails with "Merge commits are not
      -- allowed on this repository" from the GraphQL mergePullRequest call.
      default_merge_method = lendable.default_merge_method,
      diff = {
        open_cmd = "AtlasDiff",
        layout = "inline",
        compact = true,
        -- Backs the new side of the diff with a detached worktree at the PR head so
        -- LSP servers attach to real files. Worktrees live under stdpath("cache")/atlas.
        lsp = {
          enabled = true,
          link = lendable.vendor_links,
        },
        explorer = { grouped = true, show_commits = true, width = 40 },
      },
      -- AtlasDiff resolves owner/repo → local checkout via this map. Without it
      -- you'll see "no repo_paths mapping for '<owner>/<repo>'". The wildcard
      -- form maps everything under <root>; explicit entries always win.
      repo_config = {
        paths = vim.tbl_extend("force", {
          ["mateuszsip/*"] = vim.env.ATLAS_REPOS_ROOT and (vim.env.ATLAS_REPOS_ROOT .. "/prv/*") or "~/dev/prv/*",
        }, lendable.repo_paths),
      },
      github = {
        views = github_pull_views,
      },
    },
    issues = {
      max_results = 200,
      with_relationships = true,
      github = {
        views = github_issue_views,
      },
      jira = {
        project_config = lendable.jira_project_config,
        views = jira_views,
        bookmarks = {
          items = lendable.jira_bookmarks,
        },
      },
    },
    -- Shared per-provider settings (auth, cache); views/bookmarks live under
    -- the pulls/issues sections above.
    providers = {
      github = {
        cache_ttl = 300,
      },
      jira = lendable.jira_provider,
    },
  },
  keys = {
    -- <leader>g* — search/PR/jira binds (replaces LazyVim octo extra + user's octo.lua).
    { "<leader>gp", "<cmd>Atlas search github<CR>", desc = "Search PRs/issues (Atlas)" },
    { "<leader>gi", "<cmd>Atlas issues github<CR>", desc = "List GitHub Issues (Atlas)" },
    {
      "<leader>gI",
      function()
        local provider = require("atlas.providers").load("github", "issues")
        require("atlas.issues.actions").run("search", { provider = provider })
      end,
      desc = "Search GitHub Issues (Atlas)",
    },
    -- `gr` (Octo repo list) has no atlas equivalent — opening the panel shows repos.
    { "<leader>gS", "<cmd>Atlas search github<CR>", desc = "Search (Atlas)" },
    { "<leader>gC", "<cmd>Atlas create pr<CR>", desc = "Create PR (Atlas)" },
    {
      "<leader>gD",
      function()
        vim.ui.input({ prompt = "Atlas diff (URL or base...head): " }, function(input)
          if input and input ~= "" then
            vim.cmd("Atlas diff " .. input)
          end
        end)
      end,
      desc = "Atlas diff (review PR/range)",
    },
    { "<leader>gO", "<cmd>Atlas notes<CR>", desc = "Local review notes (Atlas)" },

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
    {
      "<leader>gR",
      function()
        atlas_pulls_repo(nil)
      end,
      desc = "Search PRs (current repo)",
    },
    {
      "<leader>ga",
      function()
        atlas_pulls_by_author("repo")
      end,
      desc = "PRs by author (current repo)",
    },
    {
      "<leader>gA",
      function()
        atlas_pulls_by_author("all")
      end,
      desc = "PRs by author (all repos)",
    },

    -- Multi-select yank of PR URLs (<Tab> marks, <CR> confirms under snacks).
    -- Mirrors the gm/gM scoping above.
    {
      "<leader>gy",
      function()
        copy_pr_links("repo")
      end,
      desc = "Copy links: my open PRs (current repo)",
    },
    {
      "<leader>gY",
      function()
        copy_pr_links("all")
      end,
      desc = "Copy links: my open PRs (all repos)",
    },

    -- Jira (replaces letieu/jira.nvim). No board UI — these open atlas's issue list.
    {
      "<leader>ji",
      function()
        vim.ui.input({ prompt = "Issue key: ", default = "CARD-" }, function(key)
          if key and key ~= "" then
            vim.cmd("Atlas open " .. key)
          end
        end)
      end,
      desc = "Jira: View issue (Atlas)",
    },
    { "<leader>jj", open_view("issues", "jira", jira_views, "My tasks"), desc = "Jira: My tasks (Atlas)" },
    { "<leader>jb", open_view("issues", "jira", jira_views, "My board tasks"), desc = "Jira: My board tasks (Atlas)" },
    { "<leader>js", open_view("issues", "jira", jira_views, "Active sprint"), desc = "Jira: Active sprint (Atlas)" },
    { "<leader>je", "<cmd>Atlas issues jira<CR>", desc = "Jira: Edit issue (press ge in panel)" },
    { "<leader>jc", "<cmd>Atlas create issue<CR>", desc = "Jira: Create issue (Atlas)" },
    -- jira.nvim's auth login/info have no atlas equivalent; checkhealth reports creds.
    { "<leader>jl", "<cmd>checkhealth atlas<CR>", desc = "Atlas: Check Jira/GitHub auth" },
  },
  cmd = { "Atlas" },
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

    sort.wrap_set_issues()
    sort.disable_relationships_for_flat_views()
    sort.wrap_fetch_pullrequests()
  end,
}
