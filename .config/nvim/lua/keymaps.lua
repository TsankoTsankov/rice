vim.g.mapleader = " "
local map = vim.keymap.set

-- Save and quit
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- File explorer
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

-- Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Find help" })

-- Harpoon
map("n", "<leader>a", ":lua require('harpoon.mark').add_file()<CR>", { desc = "Harpoon add file" })
map("n", "<leader>h", ":lua require('harpoon.ui').toggle_quick_menu()<CR>", { desc = "Harpoon menu" })

-- Markdown Preview
--map("n", "<leader>mp", ":MarkdownPreview<CR>", { desc = "Markdown Preview" })
--map("n", "<leader>mp", "Toggle Markdown Inline" ":lua require('render-markdown').toggle()")
map("n", "<leader>mp", ":lua require('render-markdown').toggle()<CR>", { desc = "Toggle Markdown Inline" })


-- Vimtex
map("n", "<leader>lv", ":VimtexView<CR>", { desc = "Vimtex View PDF" })

-- Which-key
map("n", "<leader>?", ":WhichKey<CR>", { desc = "Show which-key" }) 
