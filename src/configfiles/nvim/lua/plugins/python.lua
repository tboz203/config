-- if true then return {} end

local pyutil = require("config.pyutil")

return {

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix_most", "ruff_format" },
      },
      formatters = {
        ruff_fix_most = {
          command = "ruff",
          args = {
            "check",
            "--fix",
            "--force-exclude",
            "--select=F,E,I",
            "--ignore=F401",
            "--exit-zero",
            "--no-cache",
            "--stdin-filename",
            "$FILENAME",
            "-",
          },
          stdin = true,
          cwd = require("conform.util").root_file({
            "pyproject.toml",
            "ruff.toml",
            ".ruff.toml",
          }),
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "htmldjango",
        "python",
        "requirements",
        "rst",
        "toml",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    ---@type PluginLspOpts
    opts = {
      servers = {
        pylsp = {
          autostart = false,
        },
        ruff = {
          init_options = {
            settings = {
              lineLength = 119,
              logLevel = "debug",
            },
          },
          commands = {
            RuffChangeSetting = {
              pyutil.ruff_change_setting,
              desc = "Change a setting for the Ruff language server",
              nargs = "+",
            },
          },
        },
        pyright = {
          on_init = pyutil.pyright_on_init,
          commands = {
            PyrightAddExtraPath = {
              function(path)
                pyutil.pyright_add_extra_paths(nil, path)
              end,
              desc = "Add a directory to Pyright's `sys.path`",
              nargs = 1,
              complete = "dir",
            },
            PyrightToggleDiagnosticMode = {
              pyutil.pyright_toggle_diagnostic_mode,
              desc = "Toggle Pyright's diagnostic mode between 'workspace' and 'openFilesOnly'",
            },
          },
        },
      },
    },
  },
}
