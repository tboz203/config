local M = {}
local lzutil = require("lazy.core.util")
local util = require("config.util")
local Path = require("config.path")

-- add a path (or the current buffer name) to Pyright's package search path
---@param client vim.lsp.Client?
---@param ... string
---@return nil
function M.pyright_add_extra_paths(client, ...)
  if client == nil then
    local client_list = vim.lsp.get_clients({ name = "pyright", bufnr = 0 })
    _, client = next(client_list, nil)
    if client == nil then
      vim.nofity("Can't find client!", vim.log.levels.ERROR)
      return
    end
  end

  local paths = { ... }
  if not next(paths) then
    paths = { vim.api.nvim_buf_get_name(0) }
  end

  local settings = client.settings or client.config.settings
  local extra_paths = util.deepen(settings, "python", "analysis", "extraPaths")
  util.set_add(extra_paths, paths)
  client.notify("workspace/didChangeConfiguration", { settings = settings })
  -- vim.notify(string.format("Pyright extra paths set to: %s", vim.inspect(extra_paths)))
end

-- tell pyright which python executable to use
---@param client vim.lsp.Client?
---@param path string
---@return nil
function M.pyright_set_python_path(client, path)
  if client == nil then
    local client_list = vim.lsp.get_clients({ name = "pyright", bufnr = 0 })
    _, client = next(client_list, nil)
    if client == nil then
      vim.nofity("Can't find client!", vim.log.levels.ERROR)
      return
    end
  end

  lzutil.merge(client.config.settings, {
    python = {
      pythonPath = path,
    },
  })

  client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  -- vim.notify(string.format("Pyright python path set to: %s", vim.inspect(path)))
end

-- toggle Pyright's diagnostic mode between "workspace" and "openFilesOnly"
---@param client vim.lsp.Client?
---@return nil
function M.pyright_toggle_diagnostic_mode(client)
  if client == nil then
    local client_list = vim.lsp.get_clients({ name = "pyright", bufnr = 0 })
    _, client = next(client_list, nil)
    if client == nil then
      vim.nofity("Can't find client!", vim.log.levels.ERROR)
      return
    end
  end

  local settings = client.settings or client.config.settings
  local current_mode = vim.tbl_get(settings, "python", "analysis", "diagnosticMode")
  local new_mode
  if current_mode == nil or current_mode == "workspace" then
    new_mode = "openFilesOnly"
  else
    new_mode = "workspace"
  end
  lzutil.merge(settings, {
    python = {
      analysis = {
        diagnosticMode = new_mode,
      },
    },
  })
  client.notify("workspace/didChangeConfiguration", { settings = nil })
  -- vim.notify(string.format("Set Pyright diagnostic mode to `%s`", new_mode), vim.log.levels.INFO)
end

-- find closest ancestor of path `fname` whose parent directory does not contain an `__init__.py`
---@param fname string
---@return string?
function M.find_package_root(fname)
  ---@type Path
  local filepath = Path:new(fname)
  if not filepath:is_dir() then
    filepath = filepath:parent()
  end
  if not filepath:exists() then
    return nil
  end
  while true do
    local parent = filepath:parent()
    if parent == filepath then
      -- found filesystem root?
      return tostring(filepath)
    end
    if not (parent / "__init__.py"):exists() then
      -- nothing further up; this is the top directory in the package
      return tostring(filepath)
    end
    filepath = parent
  end
end

-- find a python virtual environment based on a filename. currently only searches along parents path for venvs
function M.find_venv(fname)
  local fpath = Path(fname):absoluted()
  -- vim.notify(string.format("Looking for venv at: %s", fpath))

  local venv_names = {
    "venv/pyvenv.cfg",
    ".venv/pyvenv.cfg",
  }

  -- traverse self and parent directories looking for `.../venv/pyvenv.cfg`
  local pyvenv_cfg = fpath:find_any_upwards(unpack(venv_names))

  -- if we find that,
  if pyvenv_cfg then
    -- return the path to the `venv` folder
    -- vim.notify(string.format("Found pyvenv.cfg at: %s", pyvenv_cfg))
    -- vim.notify(string.format("Returning: %s", tostring(pyvenv_cfg:parent())))
    return tostring(pyvenv_cfg:parent())
  end

  -- else complain
  -- vim.notify("Failed to find venv for path: " .. tostring(fpath), vim.log.levels.DEBUG)
  -- vim.notify("Failed to find venv for path: " .. tostring(fpath))
  return nil
end

---@param key string
---@param value any
---@return nil
function M.ruff_change_setting(key, value)
  -- lua's regular expressions don't allow repeating groups?!? (eg. `(...)*`)
  -- if not string.match(key, "^%w+(%.%w+)*$") then
  --   error("Not a valid setting: " .. key)
  -- end

  -- attempt to evaluate `value` as lua
  pcall(function()
    local f = loadstring("return " .. value)
    if f then
      value = f()
    end
  end)

  ---@type string[]
  local split_keys = {}
  for part in string.gmatch(key, "%w+") do
    split_keys[#split_keys + 1] = part
  end

  local bottom_key = split_keys[#split_keys]
  split_keys[#split_keys] = nil

  for _, client in ipairs(vim.lsp.get_clients({ name = "ruff" })) do
    vim.notify("updating ruff configuration", vim.log.levels.INFO)
    local settings =
      vim.tbl_deep_extend("force", util.deepen(client.config, "init_options", "settings"), client.settings or {})
    local bottom_setting_table = util.deepen(settings, unpack(split_keys))
    bottom_setting_table[bottom_key] = value
    client.stop()

    local timer = vim.uv.new_timer()

    if timer == nil then
      vim.notify("Unable to create timer", vim.log.levels.ERROR)
      return
    end

    local attempts = 0
    timer:start(100, 1, function()
      if not client.is_stopped() and attempts < 300 then
        vim.notify("ruff not yet stopped", vim.log.levels.INFO)
        attempts = attempts + 1
        if attempts > 250 then
          client.stop(true)
        end
        return
      end
      vim.notify("ruff is stopped", vim.log.levels.INFO)
      timer:stop()
      timer:close()
      vim.schedule(function()
        vim.notify("restarting ruff", vim.log.levels.INFO)
        require("lspconfig").ruff.setup({
          init_options = {
            settings = settings,
          },
        })
      end)
    end)
  end
end

---@param client vim.lsp.Client
---@return nil
function M.pyright_on_init(client)
  -- vim.notify("Initializing Pyright LSP client")
  if client.root_dir then
    -- vim.notify(string.format("Root dir is: %s", client.root_dir))
    local extra_paths = {}
    local root = Path(client.root_dir)
    -- ensure project root is in our package import search path
    table.insert(extra_paths, tostring(root))

    -- and our stubs directory, if it exists
    local stubs = root / ".stubs"
    if stubs:exists() then
      table.insert(extra_paths, tostring(stubs))
    end

    M.pyright_add_extra_paths(client, unpack(extra_paths))

    local venv = M.find_venv(client.root_dir)

    if venv ~= nil then
      venv = Path(venv)
      for _, candidate in ipairs({ "bin/python", "scripts/python.exe" }) do
        local executable = (venv / candidate):normalized()
        -- vim.notify(string.format("Checking: %s", executable))
        if executable:exists() then
          -- vim.notify(string.format("Setting python path to: %s", executable))
          M.pyright_set_python_path(client, executable:normalize())
          break
        end
      end
    else
      -- vim.notify(string.format("Venv not found for: %s", client.root_dir))
    end
  end

  require("lazyvim.util").lsp.on_attach(M.pyright_on_attach, "pyright")
end

---@param client vim.lsp.Client
---@param bufnr integer
---@return nil
function M.pyright_on_attach(client, bufnr)
  vim.keymap.set("n", "<leader>cD", function()
    M.pyright_toggle_diagnostic_mode(client)
  end, {
    desc = "Toggle Pyright diagnostic mode",
    buffer = true,
  })
end

return M
