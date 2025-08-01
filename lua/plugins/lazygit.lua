return {
  -- No need to add "kdheepak/lazygit.nvim" — we'll launch it ourselves
  {
    "akinsho/toggleterm.nvim",
    keys = {
      {
        "<leader>gg",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local lazygit = Terminal:new({
            cmd = "lazygit",
            hidden = true,
            direction = "float", -- or "tab", "horizontal", etc.
            float_opts = {
              border = "curved",
            },
          })
          lazygit:toggle()
        end,
        desc = "LazyGit (ToggleTerm)",
      },
    },
  },
}
