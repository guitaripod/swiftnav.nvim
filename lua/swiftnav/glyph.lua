local M = {}

local GLYPH = {
  Struct = 'S',
  Class = 'S',
  Actor = 'A',
  Enum = 'E',
  Protocol = 'P',
  Interface = 'P',
  Function = 'f',
  Method = 'f',
  Constructor = 'i',
  Property = 'v',
  Field = 'v',
  Variable = 'v',
  Constant = 'k',
  Module = 'm',
  Extension = 'e',
  File = '·',
}

local NERD = {
  Struct = '\u{ea91}',
  Class = '\u{eb5b}',
  Actor = '\u{eb5b}',
  Enum = '\u{ea95}',
  Protocol = '\u{eb61}',
  Interface = '\u{eb61}',
  Function = '\u{f0295}',
  Method = '\u{f0295}',
  Constructor = '\u{ea8c}',
  Property = '\u{eb65}',
  Field = '\u{eb5f}',
  Variable = '\u{ea88}',
  Constant = '\u{eb5d}',
  Module = '\u{ea8b}',
  Extension = '\u{eb63}',
  File = '\u{f0214}',
}

local GROUP = {
  Struct = 'SwiftNavKindType',
  Class = 'SwiftNavKindType',
  Actor = 'SwiftNavKindType',
  Enum = 'SwiftNavKindEnum',
  Protocol = 'SwiftNavKindProtocol',
  Interface = 'SwiftNavKindProtocol',
  Function = 'SwiftNavKindFunction',
  Method = 'SwiftNavKindFunction',
  Constructor = 'SwiftNavKindFunction',
  Property = 'SwiftNavKindValue',
  Field = 'SwiftNavKindValue',
  Variable = 'SwiftNavKindValue',
  Constant = 'SwiftNavKindConstant',
  Module = 'SwiftNavKindModule',
  Extension = 'SwiftNavKindType',
  File = 'SwiftNavKindFile',
}

--- Whether Nerd Font icons are on: the `icons` option, else `vim.g.have_nerd_font`.
local function nerd_enabled()
  local config = require('swiftnav').config
  local setting = config and config.icons
  if setting == nil or setting == 'auto' then
    return vim.g.have_nerd_font == true or vim.g.have_nerd_font == 1
  end
  return setting == true
end

function M.get(kind)
  local table_ = nerd_enabled() and NERD or GLYPH
  return table_[kind] or GLYPH[kind] or '·', GROUP[kind] or 'SwiftNavKindValue'
end

return M
