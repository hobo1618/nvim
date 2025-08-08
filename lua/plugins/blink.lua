return {
  "saghen/blink.cmp",
  opts = {
    -- apply sources to all filetypes except TeX
    sources = {
      default = {
        ["*"] = { "lsp", "path", "buffer" },
        tex = {}, -- 👈 disables all blink completion in .tex
      },
    },
  },
}
