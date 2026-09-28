local M = {}
-- so far all unused

-- Action
---------

-- for utility functions
local action_state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod

M.actions = {}
M.actions.do_stuff = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
  local entry = action_state.get_selected_entry()
end

M.actions = transform_mod(M.actions)

-- Layout
---------

local Layout = require("telescope.pickers.layout")

M.create_layout = function(picker)
  local function create_window(enter, width, height, row, col, title)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(bufnr, enter, {
      style = "minimal",
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      border = "single",
      title = title,
    })

    vim.wo[winid].winhighlight = "Normal:Normal"

    return Layout.Window({
      bufnr = bufnr,
      winid = winid,
    })
  end

  local function destory_window(window)
    if window then
      if vim.api.nvim_win_is_valid(window.winid) then
        vim.api.nvim_win_close(window.winid, true)
      end
      if vim.api.nvim_buf_is_valid(window.bufnr) then
        vim.api.nvim_buf_delete(window.bufnr, { force = true })
      end
    end
  end

  local layout = Layout({
    picker = picker,
    mount = function(self)
      self.results = create_window(false, 40, 20, 0, 0, "Results")
      self.preview = create_window(false, 40, 23, 0, 42, "Preview")
      self.prompt = create_window(true, 40, 1, 22, 0, "Prompt")
    end,
    unmount = function(self)
      destory_window(self.results)
      destory_window(self.preview)
      destory_window(self.prompt)
    end,
    update = function(self) end,
  })

  return layout
end
