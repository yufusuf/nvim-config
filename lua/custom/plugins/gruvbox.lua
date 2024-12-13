return {
  "ellisonleao/gruvbox.nvim",
  name = 'gruvbox',
  config = function()
    require('gruvbox').setup({
      transparent_mode = true
    })
    vim.cmd.colorscheme('gruvbox')
  end,
}
