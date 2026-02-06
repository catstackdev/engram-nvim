-- Main engram.nvim module
local config = require('engram.config')
local commands = require('engram.commands')

local M = {}

-- Setup function called by user
function M.setup(user_config)
  -- Merge user config with defaults
  local cfg = config.setup(user_config)

  -- Create user commands
  M.create_commands()

  -- Setup keymaps if configured
  M.setup_keymaps()

  -- Setup optional features
  if cfg.tag_completion then
    local ok, completion = pcall(require, 'engram.completion')
    if ok then
      completion.setup()
    end
  end

  if cfg.auto_capture_todos then
    local ok, todo = pcall(require, 'engram.todo')
    if ok then
      todo.enable_auto_scan()
    end
  end

  -- Load offline queue
  if cfg.offline_queue then
    pcall(require, 'engram.queue')
  end

  return M
end

-- Create Neovim user commands
function M.create_commands()
  -- Capture commands
  vim.api.nvim_create_user_command('EngramCapture', function()
    commands.capture_prompt()
  end, { desc = 'Capture a note with prompt' })

  vim.api.nvim_create_user_command('EngramCaptureVisual', function()
    commands.capture_visual()
  end, { desc = 'Capture visual selection', range = true })

  vim.api.nvim_create_user_command('EngramCaptureLine', function()
    commands.capture_line()
  end, { desc = 'Capture current line' })

  vim.api.nvim_create_user_command('EngramList', function()
    commands.list_captures()
  end, { desc = 'List recent captures' })

  vim.api.nvim_create_user_command('EngramSearch', function()
    commands.search_captures()
  end, { desc = 'Search captures' })

  -- Memory commands
  vim.api.nvim_create_user_command('EngramMemoryCreate', function()
    commands.create_memory()
  end, { desc = 'Create a memory' })

  vim.api.nvim_create_user_command('EngramMemoryCore', function()
    commands.create_memory({ is_core = true })
  end, { desc = 'Create a core memory' })

  vim.api.nvim_create_user_command('EngramMemoryList', function()
    commands.list_memories_telescope()
  end, { desc = 'List memories' })

  -- Queue commands
  vim.api.nvim_create_user_command('EngramQueueSync', function()
    commands.sync_queue()
  end, { desc = 'Sync offline queue' })

  vim.api.nvim_create_user_command('EngramQueueStatus', function()
    commands.queue_status()
  end, { desc = 'Show queue status' })

  -- TODO commands
  vim.api.nvim_create_user_command('EngramScanTodos', function()
    commands.scan_todos()
  end, { desc = 'Scan buffer for TODO comments' })

  -- Health check
  vim.api.nvim_create_user_command('EngramHealth', function()
    commands.health_check()
  end, { desc = 'Check Engram API health' })
end

-- Setup keymaps from config
function M.setup_keymaps()
  local cfg = config.get()
  local keymaps = cfg.keymaps

  if not keymaps then
    return
  end

  local opts = { noremap = true, silent = true }

  -- Capture keymaps
  if keymaps.capture_visual then
    vim.keymap.set('v', keymaps.capture_visual, function()
      commands.capture_visual()
    end, vim.tbl_extend('force', opts, { desc = 'Engram: Capture selection' }))
  end

  if keymaps.capture_line then
    vim.keymap.set('n', keymaps.capture_line, function()
      commands.capture_line()
    end, vim.tbl_extend('force', opts, { desc = 'Engram: Capture line' }))
  end

  if keymaps.capture_prompt then
    vim.keymap.set('n', keymaps.capture_prompt, function()
      commands.capture_prompt()
    end, vim.tbl_extend('force', opts, { desc = 'Engram: Capture with prompt' }))
  end

  if keymaps.list_captures then
    vim.keymap.set('n', keymaps.list_captures, function()
      commands.list_captures()
    end, vim.tbl_extend('force', opts, { desc = 'Engram: List captures' }))
  end

  if keymaps.search_captures then
    vim.keymap.set('n', keymaps.search_captures, function()
      commands.search_captures()
    end, vim.tbl_extend('force', opts, { desc = 'Engram: Search captures' }))
  end

  if keymaps.sync_queue then
    vim.keymap.set('n', keymaps.sync_queue, function()
      commands.sync_queue()
    end, vim.tbl_extend('force', opts, { desc = 'Engram: Sync queue' }))
  end
end

-- Export commands for direct access
M.capture_visual = commands.capture_visual
M.capture_line = commands.capture_line
M.capture_prompt = commands.capture_prompt
M.list = commands.list_captures
M.search = commands.search_captures
M.create_memory = commands.create_memory
M.list_memories = commands.list_memories
M.health = commands.health_check
M.sync_queue = commands.sync_queue
M.queue_status = commands.queue_status
M.scan_todos = commands.scan_todos

return M
