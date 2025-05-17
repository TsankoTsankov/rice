-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- File explorer
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  -- LSP and completion
  "neovim/nvim-lspconfig",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "L3MON4D3/LuaSnip",
  -- Markdown preview
  { "iamcco/markdown-preview.nvim", build = "cd app && npm install", ft = { "markdown" } },
  -- LaTeX
  "lervag/vimtex",
  -- Git
  "tpope/vim-fugitive",
  -- Commenting
  "numToStr/Comment.nvim",
  -- Surround
  "kylechui/nvim-surround",
  -- Statusline
  "nvim-lualine/lualine.nvim",
  -- Colorscheme
  "folke/tokyonight.nvim",
  -- Harpoon
  "ThePrimeagen/harpoon",
  -- Undo tree
  "mbbill/undotree",
  -- Trouble
  "folke/trouble.nvim",
  -- Which-key
  "folke/which-key.nvim",
  -- Icons
  "nvim-tree/nvim-web-devicons",
}) 
