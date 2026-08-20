do
  vim.loader.enable()

  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '
  vim.g.have_nerd_font = true

  vim.o.autoindent = true
  vim.o.expandtab = true
  vim.o.hlsearch = false
  vim.o.guicursor = ''
  vim.o.mouse = 'a'
  vim.o.showmode = false

  vim.o.clipboard = ''

  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 10
  vim.o.confirm = true
end

do
  vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
  vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
  vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
  vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Yank to system clipboard' })

  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_text = true,
    virtual_lines = false,
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false }
      end,
    },
  }

  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
      vim.hl.on_yank()
    end,
  })
end

do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local output = (result.stderr ~= '' and result.stderr) or result.stdout or ''
      if output == '' then
        output = 'No output from build command.'
      end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then
        return
      end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
          run_build(name, { 'make', 'install_jsregexp' }, ev.data.path)
        end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then
          vim.cmd.packadd 'nvim-treesitter'
        end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---@param repo string
---@return string
local function gh(repo)
  return 'https://github.com/' .. repo
end

do
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '▎' }, ---@diagnostic disable-line: missing-fields
      change = { text = '▎' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '󰐊' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '󰐊' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '▎' }, ---@diagnostic disable-line: missing-fields
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      map('v', '<leader>hs', function()
        gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = 'git [s]tage hunk' })
      map('v', '<leader>hr', function()
        gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = 'git [r]eset hunk' })
      map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
      map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
      map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
      map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
      map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
      map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
      map('n', '<leader>hb', function()
        gitsigns.blame_line { full = true }
      end, { desc = 'git [b]lame line' })
      map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
      map('n', '<leader>hD', function()
        gitsigns.diffthis '@'
      end, { desc = 'git [D]iff against last commit' })
      map('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (this file)' })
      map('n', '<leader>hQ', function()
        gitsigns.setqflist 'all'
      end, { desc = 'git hunk [Q]uickfix list (all files)' })
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git [b]lame line' })
      map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff' })
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = 'select git hunk' })
    end,
  }

  vim.pack.add { gh 'tpope/vim-fugitive', gh 'tpope/vim-rhubarb' }

  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>c', group = '[C]ode' },
      { '<leader>d', group = '[D]ocument' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>w', group = '[W]orkspace' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  vim.pack.add { gh 'folke/tokyonight.nvim' }
  ---@diagnostic disable-next-line: missing-fields
  require('tokyonight').setup {
    style = 'night',
    transparent = true,
    styles = {
      comments = { italic = false },
    },
  }
  vim.pack.add { gh 'nyoom-engineering/oxocarbon.nvim' }

  vim.pack.add { gh 'dchinmay2/alabaster.nvim' }
  vim.o.termguicolors = true
  local function transparent()
    for _, group in ipairs {
      'Normal',
      'NormalNC',
      'NormalFloat',
      'FloatBorder',
      'SignColumn',
      'LineNr',
      'EndOfBuffer',
      'NonText',
      'Folded',
      'WinSeparator',
      'StatusLine',
      'TabLine',
    } do
      vim.api.nvim_set_hl(0, group, { bg = 'none' })
    end
  end

  vim.api.nvim_create_autocmd('ColorScheme', { callback = transparent })
  transparent()
  vim.cmd.colorscheme 'alabaster'

  vim.pack.add { gh 'folke/todo-comments.nvim', gh 'nvim-lua/plenary.nvim' }
  require('todo-comments').setup { signs = false }

  vim.pack.add { gh 'nvim-lualine/lualine.nvim' }
  require('lualine').setup {
    options = {
      icons_enabled = false,
      component_separators = '|',
      section_separators = '',
    },
  }

  vim.pack.add { gh 'nvim-mini/mini.nvim' }
  require('mini.surround').setup()

  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    MiniIcons.mock_nvim_web_devicons()
  end
end

do
  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then
    table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim')
  end

  vim.pack.add(telescope_plugins)

  require('telescope').setup {
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search [G]it [F]iles' })
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
  end, { desc = '[/] Fuzzily search in current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function()
    builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true }
  end, { desc = '[S]earch [N]eovim files' })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf
      local function map(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = buf, desc = 'LSP: ' .. desc })
      end

      map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
      map('gr', builtin.lsp_references, '[G]oto [R]eferences')
      map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
      map('<leader>D', builtin.lsp_type_definitions, 'Type [D]efinition')
      map('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
      map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

      map('grr', builtin.lsp_references, '[G]oto [R]eferences')
      map('gri', builtin.lsp_implementations, '[G]oto [I]mplementation')
      map('grd', builtin.lsp_definitions, '[G]oto [D]efinition')
      map('grt', builtin.lsp_type_definitions, '[G]oto [T]ype Definition')
      map('gO', builtin.lsp_document_symbols, 'Open Document Symbols')
      map('gW', builtin.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
    end,
  })
end

do
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      map('K', vim.lsp.buf.hover, 'Hover Documentation')
      map('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
      map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      map('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
      map('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
      map('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, '[W]orkspace [L]ist Folders')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  ---@type table<string, vim.lsp.Config>
  local servers = {
    clangd = {},
    rust_analyzer = {},

    pylsp = {
      settings = {
        pylsp = {
          plugins = {
            pycodestyle = { ignore = { 'E501' } },
          },
        },
      },
    },

    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
            return
          end
        end

        local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
        client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false },
          telemetry = { enable = false },
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
    gh 'folke/lazydev.nvim',
  }

  require('lazydev').setup {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  }

  require('mason').setup {}
  require('mason-lspconfig').setup { automatic_enable = false }

  local ensure_installed = vim.tbl_keys(servers)
  vim.list_extend(ensure_installed, { 'stylua', 'tree-sitter-cli' })
  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

do
  vim.pack.add { gh 'stevearc/conform.nvim' }

  vim.g.format_on_save_enabled = true
  vim.api.nvim_create_user_command('FormatToggle', function()
    vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
    print('Format on save: ' .. tostring(vim.g.format_on_save_enabled))
  end, { desc = 'Toggle format on save' })

  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      if not vim.g.format_on_save_enabled then
        return nil
      end
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      end
      return { timeout_ms = 500, lsp_format = 'fallback' }
    end,
    default_format_opts = {
      lsp_format = 'fallback',
    },
    formatters_by_ft = {
      lua = { 'stylua' },
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
    require('conform').format { async = true }
  end, { desc = '[F]ormat buffer' })
  vim.api.nvim_create_user_command('Format', function()
    require('conform').format { async = true }
  end, { desc = 'Format current buffer' })
end

do
  vim.pack.add {
    { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' },
    gh 'rafamadriz/friendly-snippets',
  }

  local luasnip = require 'luasnip'
  luasnip.setup {}
  require('luasnip.loaders.from_vscode').lazy_load()
  luasnip.filetype_extend('javascript', { 'javascriptreact', 'html' })

  vim.keymap.set({ 'i', 's' }, '<C-l>', function()
    luasnip.jump(1)
  end, { silent = true, desc = 'LuaSnip jump forward' })
  vim.keymap.set({ 'i', 's' }, '<C-h>', function()
    luasnip.jump(-1)
  end, { silent = true, desc = 'LuaSnip jump backward' })

  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = { preset = 'super-tab' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    sources = {
      default = { 'lazydev', 'lsp', 'path', 'snippets' },
      providers = {
        lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
  }

  vim.pack.add { gh 'windwp/nvim-autopairs' }
  require('nvim-autopairs').setup {}
end

do
  vim.pack.add {
    { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },
    { src = gh 'nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  }

  local parsers = {
    'bash',
    'c',
    'cpp',
    'diff',
    'go',
    'html',
    'javascript',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'python',
    'query',
    'rust',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
  }

  if vim.fn.executable 'tree-sitter' == 1 then
    require('nvim-treesitter').install(parsers)
  else
    vim.schedule(function()
      vim.notify(
        'tree-sitter CLI not found; parsers not installed. Wait for Mason to finish installing tree-sitter-cli, then restart Neovim.',
        vim.log.levels.WARN
      )
    end)
  end

  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then
      return
    end
    vim.treesitter.start(buf, language)

    if vim.treesitter.query.get(language, 'indents') ~= nil then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then
        return
      end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) and vim.fn.executable 'tree-sitter' == 1 then
        require('nvim-treesitter').install(language):await(function()
          treesitter_try_attach(buf, language)
        end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })

  require('nvim-treesitter-textobjects').setup {
    select = { lookahead = true },
    move = { set_jumps = true },
  }

  local select = require 'nvim-treesitter-textobjects.select'
  local move = require 'nvim-treesitter-textobjects.move'
  local swap = require 'nvim-treesitter-textobjects.swap'

  for lhs, query in pairs {
    ['aa'] = '@parameter.outer',
    ['ia'] = '@parameter.inner',
    ['af'] = '@function.outer',
    ['if'] = '@function.inner',
    ['ac'] = '@class.outer',
    ['ic'] = '@class.inner',
  } do
    vim.keymap.set({ 'x', 'o' }, lhs, function()
      select.select_textobject(query, 'textobjects')
    end, { desc = 'Select ' .. query })
  end

  vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
    move.goto_next_start('@function.outer', 'textobjects')
  end, { desc = 'Next function start' })
  vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
    move.goto_next_start('@class.outer', 'textobjects')
  end, { desc = 'Next class start' })
  vim.keymap.set({ 'n', 'x', 'o' }, ']M', function()
    move.goto_next_end('@function.outer', 'textobjects')
  end, { desc = 'Next function end' })
  vim.keymap.set({ 'n', 'x', 'o' }, '][', function()
    move.goto_next_end('@class.outer', 'textobjects')
  end, { desc = 'Next class end' })
  vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
    move.goto_previous_start('@function.outer', 'textobjects')
  end, { desc = 'Previous function start' })
  vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
    move.goto_previous_start('@class.outer', 'textobjects')
  end, { desc = 'Previous class start' })
  vim.keymap.set({ 'n', 'x', 'o' }, '[M', function()
    move.goto_previous_end('@function.outer', 'textobjects')
  end, { desc = 'Previous function end' })
  vim.keymap.set({ 'n', 'x', 'o' }, '[]', function()
    move.goto_previous_end('@class.outer', 'textobjects')
  end, { desc = 'Previous class end' })

  vim.keymap.set('n', '<leader>a', function()
    swap.swap_next '@parameter.inner'
  end, { desc = 'Swap parameter with next' })
  vim.keymap.set('n', '<leader>A', function()
    swap.swap_previous '@parameter.inner'
  end, { desc = 'Swap parameter with previous' })
end

do
  vim.pack.add {
    { src = gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
    gh 'nvim-lua/plenary.nvim',
    gh 'MunifTanjim/nui.nvim',
    gh 'nvim-tree/nvim-web-devicons',
  }
  require('neo-tree').setup {}
  vim.keymap.set('n', '<leader>n', function()
    vim.cmd.Neotree 'toggle'
  end, { silent = true, desc = '[N]eotree toggle' })

  local neotree_links = {
    NeoTreeNormal = 'Normal',
    NeoTreeNormalNC = 'Normal',
    NeoTreeEndOfBuffer = 'Normal',
    NeoTreeFloatNormal = 'NormalFloat',
    NeoTreeFloatBorder = 'FloatBorder',
    NeoTreeTitleBar = 'Title',
    NeoTreeRootName = 'Title',
    NeoTreeDirectoryName = 'Directory',
    NeoTreeDirectoryIcon = 'Directory',
    NeoTreeFileName = 'Normal',
    NeoTreeFileIcon = 'Normal',
    NeoTreeFileNameOpened = 'Special',
    NeoTreeSymbolicLinkTarget = 'Special',
    NeoTreeIndentMarker = 'NonText',
    NeoTreeExpander = 'NonText',
    NeoTreeDotfile = 'Comment',
    NeoTreeHiddenByName = 'Comment',
    NeoTreeDimText = 'Comment',
    NeoTreeFadeText1 = 'Comment',
    NeoTreeFadeText2 = 'NonText',
    NeoTreeMessage = 'Comment',
    NeoTreeGitIgnored = 'Comment',
    NeoTreeGitUntracked = 'DiagnosticHint',
    NeoTreeGitAdded = 'DiagnosticOk',
    NeoTreeGitStaged = 'DiagnosticOk',
    NeoTreeGitModified = 'DiagnosticWarn',
    NeoTreeGitUnstaged = 'DiagnosticWarn',
    NeoTreeGitRenamed = 'DiagnosticWarn',
    NeoTreeGitDeleted = 'DiagnosticError',
    NeoTreeGitConflict = 'DiagnosticError',
  }

  local function apply_neotree_links()
    for group, target in pairs(neotree_links) do
      vim.api.nvim_set_hl(0, group, { link = target })
    end
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('neotree-colors', { clear = true }),
    callback = apply_neotree_links,
  })
  apply_neotree_links()

  vim.g.copilot_no_tab_map = true
  vim.pack.add { gh 'github/copilot.vim' }
  vim.keymap.set('i', '<C-a>', 'copilot#Accept("\\<CR>")', {
    expr = true,
    replace_keycodes = false,
    desc = 'Accept Copilot suggestion',
  })
end

-- vim: ts=2 sts=2 sw=2 et
