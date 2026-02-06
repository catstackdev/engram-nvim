-- UI rendering for displays
local util = require('engram.util')
local M = {}

-- Format capture for display
function M.format_capture(capture)
  local content = util.truncate(capture.content, 80)
  local tags = capture.tags and table.concat(capture.tags, ', ') or ''
  local created = util.format_time(capture.createdAt or '')

  return string.format('[%s] %s | Tags: %s | %s', capture.source, content, tags, created)
end

-- Format memory for display
function M.format_memory(memory)
  local content = util.truncate(memory.content, 80)
  local mem_type = memory.isCore and 'Core' or 'Working'
  local created = util.format_time(memory.createdAt or '')

  return string.format('[%s] %s | %s', mem_type, content, created)
end

-- Display captures in quickfix list
function M.show_captures_quickfix(captures)
  if not captures or #captures == 0 then
    util.notify_warn('No captures found')
    return
  end

  local qf_list = {}
  for _, capture in ipairs(captures) do
    table.insert(qf_list, {
      text = M.format_capture(capture),
      type = 'I',
    })
  end

  vim.fn.setqflist(qf_list, 'r')
  vim.cmd('copen')
  util.notify_success(string.format('Showing %d captures', #captures))
end

-- Display captures using vim.ui.select
function M.show_captures_select(captures, callback)
  if not captures or #captures == 0 then
    util.notify_warn('No captures found')
    return
  end

  local items = {}
  for i, capture in ipairs(captures) do
    items[i] = M.format_capture(capture)
  end

  vim.ui.select(items, {
    prompt = 'Select capture:',
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if not choice then
      return
    end
    if callback then
      callback(captures[idx])
    end
  end)
end

-- Display in floating window
function M.show_in_float(lines, opts)
  opts = opts or {}
  local width = opts.width or 80
  local height = opts.height or 20

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- Calculate window position (centered)
  local ui = vim.api.nvim_list_uis()[1]
  local win_height = ui.height
  local win_width = ui.width

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Window options
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.border or 'rounded',
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Close on q or <Esc>
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })

  return buf, win
end

return M
