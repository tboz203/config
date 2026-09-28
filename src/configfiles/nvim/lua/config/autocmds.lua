-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- set diagnostics state for buffer from global for new buffers
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    require("config.util").update_current_buffer_diagnostics()
  end,
})

local function augroup(name, autocmds)
  local group = vim.api.nvim_create_augroup(name, { clear = true })
  for _, autocmd in pairs(autocmds) do
    autocmd[2]["group"] = group
    vim.api.nvim_create_autocmd(autocmd[1], autocmd[2])
  end
end

local auto_win_save_view_state = {}
augroup("auto_win_save_view", {
  {
    "BufLeave",
    {
      callback = function()
        auto_win_save_view_state[vim.api.nvim_get_current_buf()] = vim.fn.winsaveview()
      end,
    },
  },
  {
    "BufEnter",
    {
      callback = function()
        local buf_id = vim.api.nvim_get_current_buf()
        local saved_view = auto_win_save_view_state[buf_id]
        if saved_view == nil then
          return
        end
        local current_view = vim.fn.winsaveview()
        if current_view.lnum == 1 and current_view.col == 0 then
          vim.fn.winrestview(saved_view)
        end
        auto_win_save_view_state[buf_id] = nil
      end,
    },
  },
})
