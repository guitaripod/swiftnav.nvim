local M = {}

local defaults = {
  icons = 'auto',
  keymaps = {
    open = '<leader>so',
    jump = '<leader>sj',
    related = '<leader>sR',
    reveal = '<leader>sS',
  },
  index = {
    preload = true,
  },
  nav = {
    pick_margin = 150,
    weights = {},
  },
}

local function highlights()
  local groups = {
    SwiftNavSelection = 'PmenuSel',
    SwiftNavStatus = 'Comment',
    SwiftNavName = 'Normal',
    SwiftNavContainer = 'Comment',
    SwiftNavPath = 'Comment',
    SwiftNavKindType = '@type',
    SwiftNavKindEnum = '@lsp.type.enum',
    SwiftNavKindProtocol = '@lsp.type.interface',
    SwiftNavKindConstant = '@constant',
    SwiftNavMatch = 'Special',
    SwiftNavKindFunction = '@function',
    SwiftNavKindValue = '@variable.member',
    SwiftNavKindModule = '@module',
    SwiftNavKindFile = '@constant',
    SwiftNavSection = 'Title',
    SwiftNavPreviewLine = 'CursorLine',
    SwiftNavBarFile = 'Title',
    SwiftNavBarType = '@type',
    SwiftNavBarMember = '@function',
    SwiftNavBarSeparator = 'Comment',
  }
  for name, link in pairs(groups) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

local function guard(action)
  return function()
    if not require('swiftnav.util').swift_context() then
      require('swiftnav.util').notify('not in a Swift project', vim.log.levels.WARN)
      return
    end
    action()
  end
end

local function nav_keymaps(bufnr)
  local nav = require('swiftnav.nav')
  local function map(lhs, rhs, description)
    vim.keymap.set('n', lhs, rhs, {
      buffer = bufnr,
      silent = true,
      desc = 'swiftnav: ' .. description,
    })
  end
  map('gd', nav.definition, 'definition')
  map('gD', nav.declaration, 'declaration')
  map('gy', nav.type_definition, 'type definition')
  map('gi', nav.implementation, 'implementations')
  map('gr', nav.references, 'references')
  map('grr', nav.references, 'references')
  map('gri', nav.implementation, 'implementations')
  map('grt', nav.type_definition, 'type definition')
  map('K', nav.hover, 'hover')
  map('gO', function()
    require('swiftnav.jumpbar').open()
  end, 'document items')
  map('<C-]>', nav.definition, 'jump to definition')
end

local function preload(bufnr)
  if not M.config.index.preload then
    return
  end
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      require('swiftnav.indexer').ensure(bufnr, function() end, false)
    end
  end, 1500)
end

--- Attach navigation, breadcrumbs and index preloading to a Swift buffer.
function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  require('swiftnav.jumpbar').attach(bufnr)
  nav_keymaps(bufnr)
  preload(bufnr)
end

local function commands()
  vim.api.nvim_create_user_command('SwiftOpen', function(opts)
    require('swiftnav.open').open({ prefill = opts.args ~= '' and opts.args or nil })
  end, { nargs = '?', desc = 'Xcode-style Open Quickly' })

  vim.api.nvim_create_user_command('SwiftJump', function()
    require('swiftnav.jumpbar').open()
  end, { desc = 'Xcode-style document items' })

  vim.api.nvim_create_user_command('SwiftRelated', function()
    require('swiftnav.related').open()
  end, { desc = 'Callers, callees, overrides and conformances' })

  vim.api.nvim_create_user_command('SwiftReveal', function()
    require('swiftnav.jumpbar').reveal()
  end, { desc = 'Reveal the file in the project tree' })

  vim.api.nvim_create_user_command('SwiftNavDebug', function()
    require('swiftnav.nav').explain()
  end, { desc = 'Explain the ranking of definition candidates under the cursor' })

  vim.api.nvim_create_user_command('SwiftWarm', function()
    require('swiftnav.index').warm()
  end, { desc = 'Build the sourcekit-lsp index ahead of a session' })

  vim.api.nvim_create_user_command('SwiftIndex', function()
    local indexer = require('swiftnav.indexer')
    require('swiftnav.nav').reset_build_settings()
    indexer.rebuild()
    indexer.ensure(0, function()
      local count, root = indexer.stats()
      require('swiftnav.util').notify(string.format('%d declarations in %s', count, vim.fs.basename(root or '')))
    end, true)
  end, { desc = 'Rebuild the Swift declaration index' })
end

local function leader_keymaps()
  local maps = M.config.keymaps
  if maps == false then
    return
  end
  local function map(lhs, action, description)
    if lhs and lhs ~= '' then
      vim.keymap.set('n', lhs, guard(action), { desc = description })
    end
  end
  map(maps.open, function()
    require('swiftnav.open').open()
  end, 'Open Quickly (Swift)')
  map(maps.jump, function()
    require('swiftnav.jumpbar').open()
  end, 'Swift document items')
  map(maps.related, function()
    require('swiftnav.related').open()
  end, 'Swift related items')
  map(maps.reveal, function()
    require('swiftnav.jumpbar').reveal()
  end, 'Reveal in project tree')
end

--- Set up swiftnav. Options: keymaps (table or false) and index.preload.
function M.setup(opts)
  if M.did_setup then
    return
  end
  M.did_setup = true
  M.config = vim.tbl_deep_extend('force', defaults, opts or {})

  highlights()
  require('swiftnav.index').setup()
  require('swiftnav.indexer').setup()

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'swift',
    callback = function(event)
      M.attach(event.buf)
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == 'swift' then
      M.attach(bufnr)
    end
  end

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
    callback = function(event)
      if vim.bo[event.buf].filetype ~= 'swift' then
        vim.wo[vim.api.nvim_get_current_win()].winbar = ''
      end
    end,
  })

  commands()
  leader_keymaps()
end

return M
