-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`

vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.3',
        -- or                            , branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    use({
        'Mofiqul/dracula.nvim',
        as = 'dracula',
        config = function()
            vim.cmd('colorscheme dracula')
        end
    })


    use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })

    use('nvim-treesitter/playground')
    use('theprimeagen/harpoon')
    use('mbbill/undotree')
    use('tpope/vim-fugitive')

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            --- Uncomment these if you want to manage LSP servers from neovim
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'L3MON4D3/LuaSnip' },
        }
    }

    use {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
    }

    use 'm4xshen/autoclose.nvim'

    use {
        "zbirenbaum/copilot.lua",
        -- cmd = "Copilot",
        -- event = "VimEnter",
        config = function()
            vim.defer_fn(function()
                vim.cmd('packadd copilot');
                require("copilot").setup()
            end, 100)
        end,
    }

    use {
        "zbirenbaum/copilot-cmp",
        after = { "copilot.lua" },
        config = function()
            require("copilot_cmp").setup()
        end
    }

    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons', -- optional
        },
    }

    use 'nvim-pack/nvim-spectre'

    use 'neovim/nvim-lspconfig'
    use 'simrat39/rust-tools.nvim'
    use {
        'saecki/crates.nvim',
        tag = 'v0.4.0',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('crates').setup()
        end,
    }
    -- Debugging
    use 'mfussenegger/nvim-dap'

    use({
        "nvim-treesitter/nvim-treesitter-textobjects",

        after = "nvim-treesitter",
        requires = "nvim-treesitter/nvim-treesitter",
    })

    use "preservim/vim-pencil"
end)
