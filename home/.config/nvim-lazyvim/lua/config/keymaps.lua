-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

map({ "i", "n" }, "<C-c>", "<ESC>")
map("i", "<C-q>", "<C-V>")
vim.keymap.del({ "n", "x" }, "p")
vim.keymap.del({ "n", "x" }, "P")

map("x", "<leader>P", '"_dP', { noremap = true, desc = "Safe paste (black-hole)" })
map("x", "<C-p>", '"_dP', { noremap = true, desc = "Safe paste (black-hole)" })
map("n", "<S-j>", "gJ", { noremap = true })
--map({ "n", "i", "v" }, "<C-d>", "<C-d>zz")
--map({ "n", "i", "v" }, "<C-u>", "<C-u>zz")
