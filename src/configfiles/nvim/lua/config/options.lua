-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim/bin/python")
-- vim.g.node_host_prog = vim.fn.expand("~/.nodenv/versions/22.13.1/bin/node")

-- Set to "solargraph" to use solargraph instead of ruby_lsp.
-- vim.g.lazyvim_ruby_lsp = "ruby_lsp"
-- vim.g.lazyvim_ruby_lsp = "solargraph"

vim.g.snacks_animate = false

-- vim.lsp.set_log_level(vim.log.levels.DEBUG)

-- vim.o.autowrite = false
-- vim.o.autowriteall = false
-- vim.o.hidden = true

vim.o.linebreak = true

vim.o.wrapscan = false
vim.o.relativenumber = false

vim.o.history = 1e4

vim.o.tabstop = 4
vim.o.shiftwidth = 0
vim.o.softtabstop = -1
vim.o.expandtab = true
vim.o.smartindent = false
vim.o.breakindent = true

vim.opt.spelloptions:append("camel")

vim.opt.listchars = {
  tab = ">-",
  trail = "-",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}

vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "folds",
  "globals",
  "help",
  "localoptions",
  "options",
  "skiprtp",
  "tabpages",
  "winsize",
}

-- vim.opt.directory = { "~/.vim/swap//", "." }
---@diagnostic disable-next-line
local swapdir = vim.fs.joinpath(vim.fn.stdpath("state"), "swap")
vim.fn.mkdir(swapdir, "p")
vim.opt.directory = { swapdir .. "//", "." }

vim.o.shada = "!,'100,s1000"
vim.opt.sessionoptions = {
  -- "blank",
  "buffers",
  "curdir",
  "folds",
  "globals",
  "help",
  "localoptions",
  "options",
  -- "skiprtp",
  "tabpages",
  "winsize",
}

vim.opt.jumpoptions = { "stack", "view" }

vim.opt.diffopt:append({ "iwhiteall", "vertical", "closeoff", "hiddenoff", "algorithm:histogram" })
