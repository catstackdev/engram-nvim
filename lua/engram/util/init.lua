-- Utility functions
local M = {}

-- Get current context (file, line, git branch, etc.)
function M.get_context()
  local context = {}

  -- File path
  local bufnr = vim.api.nvim_get_current_buf()
  context.file = vim.api.nvim_buf_get_name(bufnr)

  -- Line number
  local cursor = vim.api.nvim_win_get_cursor(0)
  context.line = cursor[1]
  context.column = cursor[2]

  -- Git branch (if in git repo)
  local git_branch = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>/dev/null')
  if vim.v.shell_error == 0 then
    context.git_branch = vim.trim(git_branch)
  end

  -- Filetype
  context.filetype = vim.bo.filetype

  -- Project root (if using vim.fn.getcwd())
  context.cwd = vim.fn.getcwd()

  return context
end

-- Get visual selection text
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  -- Handle single line selection
  if #lines == 1 then
    local start_col = start_pos[3]
    local end_col = end_pos[3]
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    -- Trim first and last lines
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end

  return table.concat(lines, '\n')
end

-- Get current line text
function M.get_current_line()
  local line = vim.api.nvim_get_current_line()
  return vim.trim(line)
end

-- Extract tags from text (words starting with #)
function M.extract_tags(text)
  local tags = {}
  for tag in string.gmatch(text, '#(%w+)') do
    table.insert(tags, tag)
  end
  return tags
end

-- Remove tags from text
function M.remove_tags(text)
  return string.gsub(text, '#%w+%s*', '')
end

-- Truncate text to max length
function M.truncate(text, max_length)
  if #text <= max_length then
    return text
  end
  return string.sub(text, 1, max_length - 3) .. '...'
end

-- Format timestamp
function M.format_time(iso_string)
  -- Parse ISO 8601 timestamp and format as readable
  local pattern = '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)'
  local year, month, day, hour, min, sec = iso_string:match(pattern)

  if not year then
    return iso_string
  end

  return string.format('%s-%s-%s %s:%s', year, month, day, hour, min)
end

-- Notify with consistent styling
function M.notify(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify('[Engram] ' .. msg, level)
end

-- Notify success
function M.notify_success(msg)
  M.notify(msg, vim.log.levels.INFO)
end

-- Notify error
function M.notify_error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

-- Notify warning
function M.notify_warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

return M
