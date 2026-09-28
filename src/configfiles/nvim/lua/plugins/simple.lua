-- if true then return {} end

return {
  { "tpope/vim-fugitive" },
  { "tpope/vim-repeat" },
  { "tpope/vim-sensible" },
  { "tpope/vim-sleuth" },
  { "tpope/vim-unimpaired" },

  { "s1n7ax/nvim-window-picker" },

  { "godlygeek/tabular", cmd = "Tabularize", version = "*" },

  -- disabling b/c it seems to be fighting with vim-sleuth
  { "sheerun/vim-polyglot", cond = false },

  { "towolf/vim-helm", ft = "helm", cond = "false" },

  -- { "echasnovski/mini.nvim", cond = false },
  -- { "echasnovski/mini.ai", cond = false },
  -- { "echasnovski/mini.align", cond = false },
  -- { "echasnovski/mini.pairs", cond = false },
  -- { "echasnovski/mini.surround", cond = false },
  -- { "echasnovski/mini.animate", cond = false },
}
