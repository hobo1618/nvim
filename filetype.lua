-- this is necessary for the markdown treesitter parser to 
-- identify mdx files as markdown files, as noted in this
-- article: https://phelipetls.github.io/posts/mdx-syntax-highlight-treesitter-nvim/ 
vim.filetype.add({
    extension = {
        mdx = 'mdx'
    }
})
