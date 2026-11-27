local M = {}

local function executable(name, required, hint)
  if vim.fn.executable(name) == 1 then
    vim.health.ok(name .. ' found: ' .. vim.fn.exepath(name))
  elseif required then
    vim.health.error(name .. ' not found', hint)
  else
    vim.health.warn(name .. ' not found', hint)
  end
end

--- `:checkhealth swiftnav`
function M.check()
  vim.health.start('swiftnav')
  if vim.fn.has('nvim-0.11') == 1 then
    vim.health.ok('Neovim ' .. tostring(vim.version()))
  else
    vim.health.error('Neovim 0.11 or newer is required')
  end

  executable('rg', true, 'Install ripgrep; the declaration index needs it')
  executable('fd', false, 'Install fd for faster file listing in Open Quickly')
  executable('sourcekit-lsp', false, 'Install a Swift toolchain for LSP navigation')

  if pcall(vim.treesitter.language.add, 'swift') then
    vim.health.ok('Swift treesitter parser available')
  else
    vim.health.warn('Swift treesitter parser missing', 'Enclosing-type ranking and receiver types need it')
  end

  local cache = vim.fn.stdpath('cache') .. '/swiftnav'
  vim.fn.mkdir(cache, 'p')
  if vim.fn.filewritable(cache) == 2 then
    vim.health.ok('Index cache writable: ' .. cache)
  else
    vim.health.error('Index cache not writable: ' .. cache)
  end

  local indexer = require('swiftnav.indexer')
  local count, root = indexer.stats()
  if root then
    vim.health.info(string.format('%d declarations indexed under %s', count or 0, root))
  else
    vim.health.info('No index loaded yet; open a Swift file')
  end
end

return M
