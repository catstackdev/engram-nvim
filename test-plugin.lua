-- Quick test script for engram.nvim
-- Run with: nvim -u test-plugin.lua

-- Minimal init for testing
vim.opt.rtp:prepend('.')

-- Setup the plugin
local ok, engram = pcall(require, 'engram')
if not ok then
  print('Failed to load engram.nvim')
  print(engram)
  return
end

-- Configure with defaults
engram.setup({
  api_url = 'http://localhost:3000',
  debug = true,
})

-- Test commands
print('✓ Plugin loaded successfully')
print('✓ Commands available:')
print('  - :EngramCapture')
print('  - :EngramCaptureVisual')
print('  - :EngramCaptureLine')
print('  - :EngramList')
print('  - :EngramSearch')
print('  - :EngramMemoryCreate')
print('  - :EngramMemoryList')
print('  - :EngramHealth')
print('')
print('Run :EngramHealth to test API connection')
