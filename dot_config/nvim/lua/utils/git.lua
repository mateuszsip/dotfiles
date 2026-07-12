local M = {}

---Return the repo's default branch ("main" or "master"), prefixed with
---"origin/" when remote=true. Returns nil if neither ref exists.
---@param remote? boolean
---@return string?
function M.default_branch(remote)
  local prefix = remote and "refs/remotes/origin/" or "refs/heads/"
  local display = remote and "origin/" or ""
  for _, name in ipairs({ "main", "master" }) do
    vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", prefix .. name })
    if vim.v.shell_error == 0 then
      return display .. name
    end
  end
  return nil
end

---Open Diffview against the repo's default branch (local or origin).
---@param remote? boolean
function M.diffview_against(remote)
  local branch = M.default_branch(remote)
  if not branch then
    return Snacks.notify.warn(
      "No " .. (remote and "origin/main or origin/master" or "main or master") .. " found"
    )
  end
  vim.cmd("DiffviewOpen " .. branch)
end

return M
