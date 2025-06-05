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
        lazy = false, -- Often desired for file explorers so it's ready on startup
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local HEIGHT_RATIO = 0.8
            local WIDTH_RATIO = 0.5

            require("nvim-tree").setup({
                disable_netrw = true,
                view = {
                    -- Default view width (for non-floating)
                    width = 30,
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
                            local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
                            return {
                                border = "rounded",
                                relative = "editor",
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
                actions = {
                    open_file = {
                        quit_on_open = true,
                    },
                },
                git = {
                    enable = true,
                },
            })
        end,
    },

    -- Mason
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                -- You can specify automatic installation of servers here, e.g.:
                -- ensure_installed = { "lua_ls", "pyright" },
            })
        end,
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                -- Default options for telescope
                defaults = {
                    -- Your telescope defaults here
                },
            })
        end,
    },
    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    -- LSP and completion
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip", -- Needed for LuaSnip integration with nvim-cmp
        },
        config = function()
            -- Example: Setup Lua LS. You'll add more language servers here.
            require("lspconfig").lua_ls.setup({})

            -- nvim-cmp setup
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },
    -- Markdown preview
    {
        "MeanderingProgrammer/render-markdown.nvim",
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
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },
    -- Surround
    {
        "kylechui/nvim-surround",
        config = function()
            require("nvim-surround").setup()
        end,
    },
    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                },
            })
        end,
    },
    -- Harpoon
    {
        "ThePrimeagen/harpoon",
        config = function()
            require("harpoon").setup({
                -- Your harpoon configuration here
            })
        end,
    },
    -- Undo tree
    {
        "mbbill/undotree",
        config = function()
            -- You might want to add a keybinding here, e.g.:
            -- vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undotree" })
        end,
    },
    -- Trouble
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-web-devicons" }, -- For icons in trouble.nvim
        config = function()
            require("trouble").setup({
                -- Your trouble.nvim configuration here
            })
        end,
    },
    -- Which-key
    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup({
                -- Your which-key configuration here
            })
        end,
    },
    -- Icons (often pulled as a dependency by other plugins)
    "nvim-tree/nvim-web-devicons",
})

-- The previous floating tree setup block at the end is now incorporated
-- into the nvim-tree plugin configuration.
