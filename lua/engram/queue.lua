-- Offline queue for when API is unavailable
local M = {}

-- Queue file location
local queue_file = vim.fn.stdpath('data') .. '/engram-queue.json'

-- In-memory queue
local queue = {}

-- Load queue from disk
function M.load()
  local file = io.open(queue_file, 'r')
  if not file then
    queue = {}
    return
  end

  local content = file:read('*all')
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if ok and data then
    queue = data
  else
    queue = {}
  end
end

-- Save queue to disk
function M.save()
  local file = io.open(queue_file, 'w')
  if not file then
    vim.notify('engram.nvim: Failed to save queue', vim.log.levels.ERROR)
    return false
  end

  local ok, json = pcall(vim.json.encode, queue)
  if not ok then
    file:close()
    return false
  end

  file:write(json)
  file:close()
  return true
end

-- Add item to queue
function M.enqueue(type, data)
  table.insert(queue, {
    type = type, -- 'capture' or 'memory'
    data = data,
    timestamp = os.time(),
    id = vim.fn.sha256(vim.json.encode(data) .. os.time()),
  })
  M.save()
end

-- Get queue length
function M.length()
  return #queue
end

-- Get all items
function M.get_all()
  return queue
end

-- Remove item by ID
function M.remove(id)
  for i, item in ipairs(queue) do
    if item.id == id then
      table.remove(queue, i)
      M.save()
      return true
    end
  end
  return false
end

-- Clear all items
function M.clear()
  queue = {}
  M.save()
end

-- Sync queue with API
function M.sync(callback)
  if #queue == 0 then
    if callback then
      callback(nil, { synced = 0, failed = 0 })
    end
    return
  end

  local rest = require('engram.rest')
  local synced = 0
  local failed = 0
  local total = #queue

  -- Process queue items sequentially
  local function process_next(index)
    if index > total then
      M.save()
      if callback then
        callback(nil, { synced = synced, failed = failed, total = total })
      end
      return
    end

    local item = queue[index]

    if item.type == 'capture' then
      rest.create_capture(item.data.content, item.data, function(err, result)
        if not err then
          M.remove(item.id)
          synced = synced + 1
        else
          failed = failed + 1
        end
        process_next(index + 1)
      end)
    elseif item.type == 'memory' then
      rest.create_memory(item.data.content, item.data, function(err, result)
        if not err then
          M.remove(item.id)
          synced = synced + 1
        else
          failed = failed + 1
        end
        process_next(index + 1)
      end)
    else
      failed = failed + 1
      process_next(index + 1)
    end
  end

  process_next(1)
end

-- Initialize queue on load
M.load()

return M
