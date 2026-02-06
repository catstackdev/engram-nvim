-- Auto-capture TODO comments
local M = {}

local config = require('engram.config')
local rest = require('engram.rest')
local util = require('engram.util')

-- TODO comment patterns by filetype
local todo_patterns = {
  lua = '%-%-+%s*TODO:%s*(.+)',
  python = '#%s*TODO:%s*(.+)',
  javascript = '//%s*TODO:%s*(.+)',
  typescript = '//%s*TODO:%s*(.+)',
  rust = '//%s*TODO:%s*(.+)',
  go = '//%s*TODO:%s*(.+)',
  c = '//%s*TODO:%s*(.+)',
  cpp = '//%s*TODO:%s*(.+)',
  vim = '"%s*TODO:%s*(.+)',
  sh = '#%s*TODO:%s*(.+)',
  ruby = '#%s*TODO:%s*(.+)',
}

-- Tracked TODOs (to avoid duplicates)
local tracked_todos = {}

-- Extract TODO from line
local function extract_todo(line, filetype)
  local pattern = todo_patterns[filetype]
  if not pattern then
    -- Fallback generic pattern
    pattern = 'TODO:%s*(.+)'
  end

  local match = line:match(pattern)
  return match and vim.trim(match) or nil
end

-- Capture TODO comment
local function capture_todo(content, line_num, file_path)
  -- Create unique ID for this TODO
  local todo_id = vim.fn.sha256(file_path .. ':' .. line_num .. ':' .. content)

  -- Check if already tracked
  if tracked_todos[todo_id] then
    return
  end

  local cfg = config.get()
  local opts = {
    tags = { 'todo', 'auto-captured' },
  }

  if cfg.include_context then
    opts.metadata = {
      file = file_path,
      line = line_num,
      auto_captured = true,
      captured_at = os.date('%Y-%m-%dT%H:%M:%S'),
    }

    -- Add git branch if available
    local git_branch = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>/dev/null')
    if vim.v.shell_error == 0 then
      opts.metadata.git_branch = vim.trim(git_branch)
    end
  end

  rest.create_capture(content, opts, function(err, result)
    if not err then
      tracked_todos[todo_id] = true
      util.notify_success(string.format('TODO captured from line %d', line_num))
    end
  end)
end

-- Scan buffer for TODOs
function M.scan_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  local file_path = vim.api.nvim_buf_get_name(bufnr)

  if file_path == '' then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found = 0

  for line_num, line in ipairs(lines) do
    local todo_content = extract_todo(line, filetype)
    if todo_content then
      capture_todo(todo_content, line_num, file_path)
      found = found + 1
    end
  end

  if found > 0 then
    util.notify_success(string.format('Found and captured %d TODO(s)', found))
  else
    util.notify('No TODOs found in current buffer')
  end
end

-- Auto-scan on save
function M.enable_auto_scan()
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('EngramTODO', { clear = true }),
    callback = function()
      local cfg = config.get()
      if cfg.auto_capture_todos then
        M.scan_buffer()
      end
    end,
  })
end

-- Clear tracked TODOs
function M.clear_tracked()
  tracked_todos = {}
  util.notify('Cleared tracked TODOs')
end

return M
