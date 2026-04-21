-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.cmd([[if argc() == 1 && isdirectory(argv(0)) | cd `=argv(0)` | endif]])
