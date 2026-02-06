-- Window management utilities
local M = {}

-- Create a centered floating window
function M.create_float(opts)
  opts = opts or {}
  local width = opts.width or 80
  local height = opts.height or 20

  -- Get editor dimensions
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return nil
  end

  local win_height = ui.height
  local win_width = ui.width

  -- Calculate position (centered)
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Window configuration
  local win_config = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.border or 'rounded',
    title = opts.title,
    title_pos = opts.title_pos or 'center',
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  return buf, win
end

-- Close a window safely
function M.close(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

return M
