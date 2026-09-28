local util = require("config.util")
util.clean_win_path()
util.fix_shell_settings()

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
