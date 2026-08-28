local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic quickfix" })

map("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left pane" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower pane" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper pane" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right pane" })
