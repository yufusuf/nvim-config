return {
  "rebelot/kanagawa.nvim",
  name = 'kanagawa',
  config = function()
    require('kanagawa').setup({
      transparent = true,
    })
    --vim.cmd('colorscheme kanagawa-dragon')
  end,
}
