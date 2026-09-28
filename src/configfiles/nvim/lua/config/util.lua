---@class LazyUtilCore
-- local M = require("lazy.core.util")
local M = {}

-- toggling diagnostics (for LSP, etc)
M.diagnostic_state = { [-1] = true }

function M.toggle_current_buffer_diagnostics()
  -- find our current state
  local buf_id = vim.api.nvim_get_current_buf()
  local buf_state = M.diagnostic_state[buf_id]
  local global_state = M.diagnostic_state[-1]

  -- if we match global state (explicit or otherwise) then
  if buf_state == nil or buf_state == global_state then
    -- set to !global_state
    if global_state then
      M.diagnostic_state[buf_id] = false
      vim.notify("Disabling diagnostics in buffer")
      vim.diagnostic.enable(false, { bufnr = buf_id })
    else
      M.diagnostic_state[buf_id] = true
      vim.notify("Enabling diagnostics in buffer")
      vim.diagnostic.enable(true, { bufnr = buf_id })
    end
  else
    -- otherwise clear buffer state & match global
    M.diagnostic_state[buf_id] = nil
    if global_state then
      vim.notify("Clearing diagnostics toggle (enabled globally)")
      vim.diagnostic.enable(true, { bufnr = buf_id })
    else
      vim.notify("Clearing diagnostics toggle (disabled globally)")
      vim.diagnostic.enable(false, { bufnr = buf_id })
    end
  end
end

function M.toggle_global_diagnostics()
  -- fetch, toggle, and store global state
  local global_state = not M.diagnostic_state[-1]
  M.diagnostic_state[-1] = global_state

  -- give notice
  if global_state then
    vim.notify("Enabling diagnostics globally")
  else
    vim.notify("Disabling diagnostics globally")
  end

  -- for each buffer
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    -- if it does not have an explicit diagnostic state:
    if M.diagnostic_state[buf_id] == nil then
      -- set appropriate diagnostic state
      if global_state then
        vim.diagnostic.enable(true, { bufnr = buf_id })
      else
        vim.diagnostic.enable(false, { bufnr = buf_id })
      end
    end
  end
end

-- enable or disable diagnostics in the current buffer based on our state
function M.update_current_buffer_diagnostics()
  -- find our current state
  local buf_id = vim.api.nvim_get_current_buf()
  local buf_state = M.diagnostic_state[buf_id]
  local global_state = M.diagnostic_state[-1]

  if buf_state or (buf_state == nil and global_state) then
    vim.diagnostic.enable(true, { bufnr = buf_id })
  else
    vim.diagnostic.enable(false, { bufnr = buf_id })
  end
end

--- Combine unique arrays. Mutates and returns the first argument.
--- To create a new unique array, pass an empty array first.
---@generic T
---@param first T[]
---@param ... T[]
---@return T[] set
function M.set_add(first, ...)
  ---@alias T T
  local rest = { ... }

  -- special case: adding a single item
  if #rest == 1 then
    local _, other = next(rest)
    if #other == 1 then
      local _, right_elem = next(other)
      for _, item in ipairs(first) do
        if item == right_elem then
          return first
        end
      end
      first[#first + 1] = right_elem
      return first
    end
  end

  ---@type table<T, true>
  --- the set of elements in the first list
  local element_set = {}
  for _, elem in ipairs(first) do
    element_set[elem] = true
  end

  ---@type table<T, true>
  --- the set of elements to be added to the first list
  local additions = {}
  for _, other in ipairs(rest) do
    for _, elem in ipairs(other) do
      if not element_set[elem] then
        additions[elem] = true
      end
    end
  end

  for elem, _ in pairs(additions) do
    first[#first + 1] = elem
  end

  return first
end

-- get or create a nested table, following the given chain of lookup keys
-- note: this mutates `tbl`
---@param tbl table
---@param ... string
---@return table tbl
function M.deepen(tbl, ...)
  local keys = { ... }
  local curr = tbl
  for i, key in ipairs(keys) do
    if type(curr) ~= "table" then
      error(vim.inspect({ message = "not a table", tbl = tbl, curr = curr, keys = keys, i = i }))
    end
    if curr[key] == nil then
      curr[key] = {}
    end
    curr = curr[key]
  end
  return curr
end

-- add a workspace folder to a specific LSP client. If a matching workspace
-- folder already exists, silently do nothing
---@param client vim.lsp.Client
---@param folder string
---@return nil
function M.lsp_client_add_workspace_folder(client, folder)
  ---@type lsp.WorkspaceFolder[]
  local client_ws_folders = client.workspace_folders or {}
  for _, ws_folder in ipairs(client_ws_folders) do
    if folder == ws_folder.name then
      return
    end
  end

  ---@type lsp.WorkspaceFolder
  local new_workspace_folder = {
    uri = vim.uri_from_fname(folder),
    name = folder,
  }

  client.notify("workspace/didChangeWorkspaceFolders", {
    event = {
      added = { new_workspace_folder },
      removed = {},
    },
  })

  ---@type lsp.WorkspaceFolder[]
  client.workspace_folders = vim.list_extend(client.workspace_folders or {}, { new_workspace_folder })
end

function M.clean_win_path()
  if vim.env.OS ~= "Windows_NT" then
    -- This isn't windows!
    return
  end

  -- get our PATH list
  local path = vim.split(vim.env.PATH, ";")
  -- vim.notify(string.format("Found path: %s", vim.inspect(path)))

  -- define directory rejection rules
  local reject_pattern = vim.regex("\\v\\c<(git\\\\mingw64|git\\\\usr\\\\bin|cygwin)>")

  -- build a "clean" path list
  local clean_path = {}
  for _, dir in ipairs(path) do
    if not reject_pattern:match_str(dir) then
      -- vim.notify(string.format("Accepting: %s", dir))
      table.insert(clean_path, dir)
      -- else
      --   vim.notify(string.format("Rejecting: %s", dir))
    end
  end

  -- replace the PATH
  vim.env.PATH = table.concat(clean_path, ";")
  -- vim.notify(string.format("New path is: %s", vim.env.PATH))
end

function M.fix_shell_settings()
  local path_sep = vim.split(package.config, "\n")[1]
  local shell_parts = vim.split(vim.o.shell, path_sep)
  local shell = shell_parts[#shell_parts]
  -- vim.notify(string.format("Shell is %s (%s)", shell, vim.o.shell))

  if string.find(shell, "sh") and string.find(vim.o.shellcmdflag, "^/") then
    -- vim.notify("Changing shellcmdflag to `-c`")
    vim.o.shellcmdflag = "-c"
  elseif string.find(shell, "cmd") and string.find(vim.o.shellcmdflag, "^-") then
    -- vim.notify("Changing shellcmdflag to `/s /c`")
    vim.o.shellcmdflag = "/s /c"
  end
end

return M
