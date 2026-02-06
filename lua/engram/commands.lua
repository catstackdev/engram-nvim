-- Command implementations
local rest = require('engram.rest')
local config = require('engram.config')
local util = require('engram.util')
local prompts = require('engram.ui.prompts')
local renderer = require('engram.ui.renderer')

local M = {}

-- Capture from visual selection
function M.capture_visual()
  local text = util.get_visual_selection()
  if not text or text == '' then
    util.notify_error('No text selected')
    return
  end

  M.capture_with_context(text)
end

-- Capture current line
function M.capture_line()
  local text = util.get_current_line()
  if not text or text == '' then
    util.notify_error('Current line is empty')
    return
  end

  M.capture_with_context(text)
end

-- Capture with prompt
function M.capture_prompt()
  prompts.capture_prompt(function(text)
    M.capture_with_context(text)
  end)
end

-- Internal: Capture with context metadata
function M.capture_with_context(content)
  local cfg = config.get()

  -- Extract tags if auto_tag enabled
  local tags = {}
  local clean_content = content

  if cfg.auto_tag then
    tags = util.extract_tags(content)
    clean_content = util.remove_tags(content)
  end

  -- Build capture options
  local opts = {
    tags = tags,
  }

  -- Include context if enabled
  if cfg.include_context then
    if cfg.enhanced_context then
      -- Try to use treesitter for enhanced context
      local ok_ts, ts = pcall(require, 'engram.treesitter')
      if ok_ts and ts.available() then
        opts.metadata = ts.get_enhanced_context()
      else
        opts.metadata = util.get_context()
      end
    else
      opts.metadata = util.get_context()
    end
  end

  -- Send to API (or queue if offline)
  local function do_capture()
    rest.create_capture(clean_content, opts, function(err, result)
      if err then
        -- If offline queue is enabled, queue the capture
        if cfg.offline_queue then
          local queue = require('engram.queue')
          queue.enqueue('capture', { content = clean_content, tags = opts.tags, metadata = opts.metadata })
          util.notify_warn('API unavailable - Queued for sync (' .. queue.length() .. ' pending)')
        else
          util.notify_error('Failed to create capture: ' .. err)
        end
        return
      end

      local msg = string.format('Capture saved! ID: %s', result.id:sub(1, 8))
      if #tags > 0 then
        msg = msg .. ' | Tags: ' .. table.concat(tags, ', ')
      end
      util.notify_success(msg)
    end)
  end

  do_capture()
end

-- List captures
function M.list_captures(opts)
  opts = opts or { limit = 50 }
  local cfg = config.get()

  -- Use Telescope if available and enabled
  if cfg.ui.use_telescope then
    local ok_telescope, telescope = pcall(require, 'engram.telescope')
    if ok_telescope and telescope then
      telescope.captures(opts)
      return
    end
  end

  -- Fallback to native UI
  rest.list_captures(opts, function(err, result)
    if err then
      util.notify_error('Failed to list captures: ' .. err)
      return
    end

    if not result or not result.items or #result.items == 0 then
      util.notify_warn('No captures found')
      return
    end

    renderer.show_captures_select(result.items, function(capture)
      M.show_capture_detail(capture)
    end)
  end)
end

-- Search captures
function M.search_captures()
  local cfg = config.get()

  -- Use Telescope if available and enabled
  if cfg.ui.use_telescope then
    local ok_telescope, telescope = pcall(require, 'engram.telescope')
    if ok_telescope and telescope then
      telescope.search({ limit = 50 })
      return
    end
  end

  -- Fallback to native UI
  prompts.search_prompt(function(query)
    rest.search_captures(query, { limit = 20 }, function(err, results)
      if err then
        util.notify_error('Search failed: ' .. err)
        return
      end

      if not results or #results == 0 then
        util.notify_warn('No results found')
        return
      end

      renderer.show_captures_select(results, function(capture)
        M.show_capture_detail(capture)
      end)
    end)
  end)
end

-- Show capture detail in floating window
function M.show_capture_detail(capture)
  local lines = {
    '═══════════════════════════════════════════════════════════',
    'ID: ' .. capture.id,
    'Source: ' .. capture.source,
    'Created: ' .. util.format_time(capture.createdAt or ''),
    '───────────────────────────────────────────────────────────',
    '',
    'Content:',
    capture.content,
    '',
  }

  if capture.tags and #capture.tags > 0 then
    table.insert(lines, 'Tags: ' .. table.concat(capture.tags, ', '))
    table.insert(lines, '')
  end

  if capture.metadata then
    table.insert(lines, 'Metadata:')
    -- Handle metadata safely (might be userdata from JSON)
    local metadata = capture.metadata
    if type(metadata) == 'table' then
      for key, value in pairs(metadata) do
        table.insert(lines, '  ' .. key .. ': ' .. tostring(value))
      end
    else
      -- If not a table, try to show as string
      local ok, json_str = pcall(vim.json.encode, metadata)
      if ok then
        table.insert(lines, '  ' .. json_str)
      else
        table.insert(lines, '  [metadata unavailable]')
      end
    end
  end

  table.insert(lines, '═══════════════════════════════════════════════════════════')

  renderer.show_in_float(lines, { width = 80, height = math.min(#lines + 2, 30) })
end

-- Create memory
function M.create_memory(opts)
  opts = opts or {}

  prompts.capture_prompt(function(content)
    prompts.tags_prompt(function(tags)
      rest.create_memory(content, {
        is_core = opts.is_core,
        tags = tags,
      }, function(err, result)
        if err then
          util.notify_error('Failed to create memory: ' .. err)
          return
        end

        local mem_type = opts.is_core and 'Core' or 'Working'
        util.notify_success(string.format('%s memory created! ID: %s', mem_type, result.id:sub(1, 8)))
      end)
    end)
  end)
end

-- List memories
function M.list_memories(opts)
  opts = opts or { limit = 20 }

  rest.list_memories(opts, function(err, results)
    if err then
      util.notify_error('Failed to list memories: ' .. err)
      return
    end

    if not results or #results == 0 then
      util.notify_warn('No memories found')
      return
    end

    local items = {}
    for i, memory in ipairs(results) do
      items[i] = renderer.format_memory(memory)
    end

    vim.ui.select(items, {
      prompt = 'Select memory:',
    }, function(choice, idx)
      if not choice then
        return
      end
      M.show_memory_detail(results[idx])
    end)
  end)
end

-- Show memory detail
function M.show_memory_detail(memory)
  local lines = {
    '═══════════════════════════════════════════════════════════',
    'ID: ' .. memory.id,
    'Type: ' .. (memory.isCore and 'Core Memory' or 'Working Memory'),
    'Created: ' .. util.format_time(memory.createdAt or ''),
    '───────────────────────────────────────────────────────────',
    '',
    'Content:',
    memory.content,
    '',
  }

  if memory.importance then
    table.insert(lines, 'Importance: ' .. tostring(memory.importance))
    table.insert(lines, '')
  end

  table.insert(lines, '═══════════════════════════════════════════════════════════')

  renderer.show_in_float(lines, { width = 80, height = math.min(#lines + 2, 30) })
end

-- Health check
function M.health_check()
  rest.health_check(function(healthy, response)
    if healthy then
      util.notify_success('Engram API is healthy')
    else
      util.notify_error('Engram API is not responding: ' .. tostring(response))
    end
  end)
end

-- Sync offline queue
function M.sync_queue()
  local queue = require('engram.queue')

  if queue.length() == 0 then
    util.notify('No items in queue')
    return
  end

  util.notify(string.format('Syncing %d queued items...', queue.length()))

  queue.sync(function(err, result)
    if err then
      util.notify_error('Sync failed: ' .. err)
      return
    end

    if result.synced > 0 then
      util.notify_success(
        string.format('Synced %d/%d items', result.synced, result.total)
      )
    end

    if result.failed > 0 then
      util.notify_warn(string.format('%d items failed to sync', result.failed))
    end
  end)
end

-- Show queue status
function M.queue_status()
  local queue = require('engram.queue')
  local items = queue.get_all()

  if #items == 0 then
    util.notify('Queue is empty')
    return
  end

  local lines = {
    '═══════════════════════════════════════════════════════════',
    'Offline Queue Status',
    '───────────────────────────────────────────────────────────',
    '',
    string.format('Total items: %d', #items),
    '',
  }

  for i, item in ipairs(items) do
    table.insert(lines, string.format('%d. [%s] %s', i, item.type, util.truncate(item.data.content, 60)))
  end

  table.insert(lines, '')
  table.insert(lines, '═══════════════════════════════════════════════════════════')
  table.insert(lines, 'Press <leader>eq to sync')

  renderer.show_in_float(lines, { width = 80, height = math.min(#lines + 2, 30) })
end

-- Scan buffer for TODOs
function M.scan_todos()
  local todo = require('engram.todo')
  todo.scan_buffer()
end

-- List memories with Telescope
function M.list_memories_telescope()
  local cfg = config.get()

  if cfg.ui.use_telescope then
    local ok_telescope, telescope = pcall(require, 'engram.telescope')
    if ok_telescope and telescope then
      telescope.memories({ limit = 50 })
      return
    end
  end

  -- Fallback to regular list
  M.list_memories({ limit = 20 })
end

return M
