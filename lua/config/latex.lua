local M = {}

function M.preview_snippet()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local snippet = table.concat(lines, "\n")

  local tex_source = [[
\documentclass[preview]{standalone}
\usepackage{amsmath, amssymb}
\begin{document}
]] .. snippet .. "\n\\end{document}"

  local tmpname = vim.fn.tempname()
  local texfile = tmpname .. ".tex"
  local f = io.open(texfile, "w")
  f:write(tex_source)
  f:close()

  -- Open in a hidden buffer just long enough to compile and preview
  vim.cmd("silent! badd " .. texfile)
  vim.cmd("silent! buffer " .. texfile)
  vim.cmd("silent! VimtexCompile")
  vim.cmd("silent! VimtexView")

  -- Return to original buffer immediately
  vim.cmd("buffer " .. buf)
end

return M
