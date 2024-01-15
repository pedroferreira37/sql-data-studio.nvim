local view = require("sql-data-studio.explorer")

vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", view.toggle)
