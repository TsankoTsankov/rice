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
    {
    "nvim-tree/nvim-tree.lua",
    lazy = false,  -- Often desired for file explorers so it's ready on startup
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {
        disable_netrw = true,
        view = {
          width = 30,
        },
        actions = {
          open_file = {
            quit_on_open = true,
          },
        },
        git = {
          enable = true,
        },
      }
    end,
  },

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
  { "MeanderingProgrammer/render-markdown.nvim", 
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "markdown" },
  config = function()
    require("render-markdown").setup({
      render_inline = true,
    })
  end,
},
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


-- Floating tree setup
local HEIGHT_RATIO = 0.8  -- You can change this
local WIDTH_RATIO = 0.5   -- You can change this too

require('nvim-tree').setup({
  view = {
    float = {
      enable = true,
      open_win_config = function()
        local screen_w = vim.opt.columns:get()
        local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
        local window_w = screen_w * WIDTH_RATIO
        local window_h = screen_h * HEIGHT_RATIO
        local window_w_int = math.floor(window_w)
        local window_h_int = math.floor(window_h)
        local center_x = (screen_w - window_w) / 2
        local center_y = ((vim.opt.lines:get() - window_h) / 2)
                         - vim.opt.cmdheight:get()
        return {
          border = 'rounded',
          relative = 'editor',
          row = center_y,
          col = center_x,
          width = window_w_int,
          height = window_h_int,
        }
        end,
    },
    width = function()
      return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
    end,
  },
})
