-- Treesitter integration for context extraction
local has_ts, ts_utils = pcall(require, 'nvim-treesitter.ts_utils')

local M = {}

-- Check if treesitter is available
function M.available()
  return has_ts
end

-- Get current function/class context
function M.get_context()
  if not has_ts then
    return nil
  end

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return nil
  end

  local context = {
    function_name = nil,
    class_name = nil,
    method_name = nil,
  }

  -- Walk up the tree to find function/class nodes
  while node do
    local node_type = node:type()

    -- Function patterns (varies by language)
    if
      node_type == 'function_declaration'
      or node_type == 'function_definition'
      or node_type == 'function'
      or node_type == 'arrow_function'
      or node_type == 'method_definition'
    then
      local name_node = node:field('name')[1]
      if name_node then
        context.function_name = vim.treesitter.get_node_text(name_node, 0)
      end
    end

    -- Class patterns
    if
      node_type == 'class_declaration'
      or node_type == 'class_definition'
      or node_type == 'class'
    then
      local name_node = node:field('name')[1]
      if name_node then
        context.class_name = vim.treesitter.get_node_text(name_node, 0)
      end
    end

    -- Method in class
    if node_type == 'method_definition' or node_type == 'function_item' then
      local name_node = node:field('name')[1]
      if name_node then
        context.method_name = vim.treesitter.get_node_text(name_node, 0)
      end
    end

    node = node:parent()
  end

  return context
end

-- Get surrounding code context (N lines above/below)
function M.get_surrounding_lines(lines_before, lines_after)
  lines_before = lines_before or 3
  lines_after = lines_after or 3

  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local total_lines = vim.api.nvim_buf_line_count(0)

  local start_line = math.max(1, current_line - lines_before)
  local end_line = math.min(total_lines, current_line + lines_after)

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  return {
    lines = lines,
    start_line = start_line,
    end_line = end_line,
    current_line = current_line,
  }
end

-- Get enhanced context with treesitter info
function M.get_enhanced_context()
  local util = require('engram.util')
  local basic_context = util.get_context()

  if not has_ts then
    return basic_context
  end

  -- Add treesitter context
  local ts_context = M.get_context()
  if ts_context then
    if ts_context.function_name then
      basic_context.function_name = ts_context.function_name
    end
    if ts_context.class_name then
      basic_context.class_name = ts_context.class_name
    end
    if ts_context.method_name then
      basic_context.method_name = ts_context.method_name
    end
  end

  -- Add surrounding code
  local surrounding = M.get_surrounding_lines(3, 3)
  if surrounding then
    basic_context.surrounding_code = table.concat(surrounding.lines, '\n')
    basic_context.code_start_line = surrounding.start_line
    basic_context.code_end_line = surrounding.end_line
  end

  return basic_context
end

return M
