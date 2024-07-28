return {
  'rose-pine/neovim',
  name = 'rose-pine',
  config = function()
    require('rose-pine').setup({
      variant = 'auto',
      disable_background = true,
    })
    --vim.cmd('colorscheme rose-pine')
  end,
}
