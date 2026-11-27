local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)

local failures, total = 0, 0

local function check(name, actual, expected)
  total = total + 1
  if not vim.deep_equal(actual, expected) then
    failures = failures + 1
    io.write(string.format('FAIL %s\n  expected %s\n  actual   %s\n', name, vim.inspect(expected), vim.inspect(actual)))
  end
end

local indexer = require('swiftnav.indexer')
local rank = require('swiftnav.rank')

local function declared(line)
  local kind, name = indexer.classify(line)
  return { kind, name }
end

check('struct', declared('struct ReviewPrompt {'), { 'Struct', 'ReviewPrompt' })
check('final class', declared('final class Store: ObservableObject {'), { 'Class', 'Store' })
check('package enum', declared('package enum Mode {'), { 'Enum', 'Mode' })
check('public actor', declared('public actor Counter {'), { 'Actor', 'Counter' })
check('protocol', declared('protocol Fetching {'), { 'Protocol', 'Fetching' })
check('nested extension', declared('extension Outer.Inner: Equatable {'), { 'Extension', 'Inner' })
check('attributed func', declared('@MainActor private func reload() {'), { 'Function', 'reload' })
check('let property', declared('    private let title: String'), { 'Property', 'title' })
check('enum case', declared('    case loading'), { 'Constant', 'loading' })
check('reserved word', declared('    let self = value'), {})

check('exact beats prefix', rank.score('store', { name = 'Store', kind = 'Struct' })
  > rank.score('store', { name = 'StoreKit', kind = 'Struct' }), true)
check('initials match', rank.score('BVC', { name = 'ButtonViewController', kind = 'Class' }) ~= nil, true)
check('non match', rank.score('zzz', { name = 'Store', kind = 'Struct' }), nil)
check('arguments dropped', rank.score('make', { name = 'make(named:)', kind = 'Function' })
  == rank.score('make', { name = 'make', kind = 'Function' }), true)
check('current file bonus', rank.score('a', { name = 'a', kind = 'Function', current_file = true })
  - rank.score('a', { name = 'a', kind = 'Function' }), 160)

local util = require('swiftnav.util')
check('substring range', util.match_ranges('ReviewPrompt', 'prom'), { { 6, 10 } })
check('subsequence ranges', util.match_ranges('ButtonViewController', 'bvc'), { { 0, 1 }, { 6, 7 }, { 10, 11 } })
check('no query', util.match_ranges('Store', ''), {})

local glyph = require('swiftnav.glyph')
vim.g.have_nerd_font = false
require('swiftnav').config = { icons = 'auto', nav = {} }
check('ascii by default', (glyph.get('Struct')), 'S')
require('swiftnav').config.icons = true
check('nerd icon', (glyph.get('Struct')) ~= 'S', true)
require('swiftnav').config = nil

local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture .. '/apps/embr/App', 'p')
vim.fn.mkdir(fixture .. '/apps/other/App', 'p')
vim.fn.mkdir(fixture .. '/Sources', 'p')
fixture = vim.uv.fs_realpath(fixture)
local function write(path, text)
  vim.fn.writefile(vim.split(text, '\n'), fixture .. '/' .. path)
end
write('Package.swift', '// swift-tools-version: 5.9')
write('apps/embr/App/ReviewPrompt.swift', 'struct ReviewPrompt {\n    func ask() {}\n}')
write('apps/embr/App/AppDelegate.swift', 'final class AppDelegate {\n    let p = ReviewPrompt()\n}')
write('apps/other/App/ReviewPrompt.swift', 'struct ReviewPrompt {\n    func ask() {}\n}')
write('Sources/Dup.swift', '// struct Commented {}\nstruct Dup {}')

require('swiftnav').setup({ keymaps = false })
vim.cmd('edit ' .. fixture .. '/apps/embr/App/AppDelegate.swift')
vim.cmd('setfiletype swift')

local done = false
indexer.ensure(0, function()
  done = true
end, false)
vim.wait(10000, function()
  return done
end, 20)
check('index built', done, true)

local items = indexer.definition_candidates('ReviewPrompt', 0)
check('both declarations indexed', #items, 2)
check('sibling directory wins', items[1] and items[1].path:find('/apps/embr/', 1, true) ~= nil, true)
check('margin clears picker', items[1].points - items[2].points >= 150, true)
check('parts reported', type(items[1].parts) == 'table' and items[1].parts.directory ~= nil, true)

require('swiftnav').config.nav.weights = { directory = 0, target = 0, same_file_type = 0, same_file_member = 0 }
local flat = indexer.definition_candidates('ReviewPrompt', 0)
check('weights override', math.abs(flat[1].points - flat[2].points) < 1, true)

write('apps/embr/App/Cart.swift', 'struct Cart {\n    func total() {}\n}\nstruct Wishlist {\n    func total() {}\n}')
write('apps/embr/App/Shop.swift', 'final class Shop {\n    let cart = Cart()\n    let list: Wishlist\n}')
indexer.update_file(fixture .. '/apps/embr/App/Cart.swift')
indexer.update_file(fixture .. '/apps/embr/App/Shop.swift')
check('type receiver', indexer.receiver_type('Cart', 0), 'Cart')
check('initializer receiver', indexer.receiver_type('cart', 0), 'Cart')
check('annotation receiver', indexer.receiver_type('list', 0), 'Wishlist')
local totals = indexer.definition_candidates('total', 0, 'Wishlist')
check('receiver picks member', totals[1].lnum == 5 and totals[1].parts.receiver ~= nil, true)

write('Sources/Gap.swift', 'import Foundation\n\n\nstruct Gap {\n}')
indexer.update_file(fixture .. '/Sources/Gap.swift')
local gap = indexer.definition_candidates('Gap', 0)
check('blank lines keep line numbers', gap[1] and gap[1].lnum, 4)

local found = indexer.search('revi', 10)
check('search finds declarations', found[1] and found[1].name, 'ReviewPrompt')
check('search skips extensions', #indexer.search('inner', 10), 0)

vim.fn.delete(fixture, 'rf')
io.write(string.format('%d checks, %d failed\n', total, failures))
vim.cmd(failures == 0 and 'qa!' or 'cq!')
