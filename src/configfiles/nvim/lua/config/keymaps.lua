-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local util = require("config.util")

-- the basics
vim.keymap.set({ "!", "o" }, "jk", "<esc>", { remap = true })
vim.keymap.set({ "!", "o" }, "Jk", "<esc>", { remap = true })
vim.keymap.set({ "!", "o" }, "jK", "<esc>", { remap = true })
vim.keymap.set({ "!", "o" }, "JK", "<esc>", { remap = true })
vim.keymap.set("n", ";", ":")

vim.keymap.set("n", "<leader>uL", "<cmd>set list!<cr>", { desc = "Toggle list characters" })

-- the +reformat group
-- stylua: ignore start
vim.keymap.set("n", "<leader>r", "", { desc = "+refactor/reformat" })
vim.keymap.set("n", "<leader>rt", "<cmd>retab!<cr>", { desc = "Retab buffer" })
vim.keymap.set("n", "<leader>rs", "<cmd>luado return line:gsub('%s+$', '')<cr>", { desc = "Remove trailing space in buffer" })
vim.keymap.set("n", "<leader>rr", "<cmd>retab! | luado return line:gsub('%s+$', '')<cr>", { desc = "Retab and Re-space buffer" })
-- stylua: ignore end

-- vi-style format command
vim.keymap.set({ "n", "v" }, "Q", "gq", { desc = "Format text" })

-- the builtin keymaps 'H' and 'L' for moving the cursor "high" and "low" are
-- overwritten in LazyVim for switching between buffers. to replace them, we
-- add these, which shadow the notionally similar zz, zt, and zb keymaps
vim.keymap.set("", "zT", "H", { desc = "Move cursor 'Top'" })
vim.keymap.set("", "zZ", "M", { desc = "Move cursor center" })
vim.keymap.set("", "zB", "L", { desc = "Move cursor 'Bottom'" })

-- toggle diagnostics (for LSP, etc)
vim.keymap.set("n", "<leader>ud", util.toggle_current_buffer_diagnostics, { desc = "Toggle Diagnostics in Buffer" })
vim.keymap.set("n", "<leader>uD", util.toggle_global_diagnostics, { desc = "Toggle Diagnostics Globally" })

-- LSP debugging
vim.keymap.set("n", "<leader>cll", "<cmd>LspInfo<cr>", { desc = "LSP Info" })
vim.keymap.set("n", "<leader>clL", "<cmd>LspLog<cr>", { desc = "LSP Log output" })
vim.keymap.set("n", "<leader>cli", function()
  local buf = vim.api.nvim_create_buf(false, true)
  local stuff = vim.split(vim.inspect(vim.lsp.get_clients()), "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, stuff)
  vim.api.nvim_open_win(buf, true, { split = "right" })
end, { desc = "Inspect LSP state" })
