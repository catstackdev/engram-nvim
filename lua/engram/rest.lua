-- REST API client for Engram backend
local async = require('engram.async')
local config = require('engram.config')

local M = {}

-- Helper to build full URL
local function build_url(endpoint)
  local cfg = config.get()
  return cfg.api_url .. endpoint
end

-- Helper to handle API response
local function handle_response(err, response, callback)
  if err then
    vim.notify('Engram API Error: ' .. err, vim.log.levels.ERROR)
    if callback then
      callback(err, nil)
    end
    return
  end

  -- Check for error response
  if response.success == false then
    local msg = response.message or 'Unknown error'
    vim.notify('Engram API Error: ' .. msg, vim.log.levels.ERROR)
    if callback then
      callback(msg, nil)
    end
    return
  end

  -- Success
  if callback then
    callback(nil, response.data)
  end
end

-- POST /capture - Create a new capture
function M.create_capture(content, opts, callback)
  opts = opts or {}
  local cfg = config.get()

  local payload = {
    content = content,
    source = opts.source or cfg.source,
    tags = opts.tags or {},
    metadata = opts.metadata or {},
  }

  async.http_request('POST', build_url('/capture'), {
    body = vim.json.encode(payload),
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- GET /capture - List captures
function M.list_captures(opts, callback)
  opts = opts or {}
  local cfg = config.get()

  local params = {}
  if opts.limit then
    table.insert(params, 'limit=' .. opts.limit)
  end
  if opts.offset then
    table.insert(params, 'offset=' .. opts.offset)
  end
  if opts.source then
    table.insert(params, 'source=' .. opts.source)
  end
  if opts.processed ~= nil then
    table.insert(params, 'processed=' .. tostring(opts.processed))
  end
  if opts.tags then
    table.insert(params, 'tags=' .. opts.tags)
  end

  local query_string = #params > 0 and ('?' .. table.concat(params, '&')) or ''

  async.http_request('GET', build_url('/capture' .. query_string), {
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- GET /capture/search - Search captures
function M.search_captures(query, opts, callback)
  opts = opts or {}
  local cfg = config.get()

  local params = { 'query=' .. vim.fn.shellescape(query) }
  if opts.limit then
    table.insert(params, 'limit=' .. opts.limit)
  end
  if opts.tags then
    table.insert(params, 'tags=' .. opts.tags)
  end

  local query_string = '?' .. table.concat(params, '&')

  async.http_request('GET', build_url('/capture/search' .. query_string), {
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- GET /capture/:id - Get single capture
function M.get_capture(id, callback)
  local cfg = config.get()

  async.http_request('GET', build_url('/capture/' .. id), {
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- POST /memory - Create memory
function M.create_memory(content, opts, callback)
  opts = opts or {}
  local cfg = config.get()

  local payload = {
    content = content,
    isCore = opts.is_core or false,
    tags = opts.tags or {},
  }

  async.http_request('POST', build_url('/memory'), {
    body = vim.json.encode(payload),
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- GET /memory - List memories
function M.list_memories(opts, callback)
  opts = opts or {}
  local cfg = config.get()

  local params = {}
  if opts.limit then
    table.insert(params, 'limit=' .. opts.limit)
  end
  if opts.is_core then
    table.insert(params, 'isCore=true')
  end

  local query_string = #params > 0 and ('?' .. table.concat(params, '&')) or ''

  async.http_request('GET', build_url('/memory' .. query_string), {
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- GET /memory/search - Search memories
function M.search_memories(query, opts, callback)
  opts = opts or {}
  local cfg = config.get()

  local params = { 'query=' .. vim.fn.shellescape(query) }
  if opts.limit then
    table.insert(params, 'limit=' .. opts.limit)
  end

  local query_string = '?' .. table.concat(params, '&')

  async.http_request('GET', build_url('/memory/search' .. query_string), {
    timeout = cfg.timeout,
  }, function(err, response)
    handle_response(err, response, callback)
  end)
end

-- GET /health - Health check
function M.health_check(callback)
  local cfg = config.get()

  async.http_request('GET', build_url('/health'), {
    timeout = 5000,
  }, function(err, response)
    if err then
      callback(false, err)
      return
    end
    callback(true, response)
  end)
end

return M
