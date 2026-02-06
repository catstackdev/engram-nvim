-- Tag completion for engram.nvim
local M = {}

-- Cache for tags
local tag_cache = {}
local cache_timestamp = 0
local cache_ttl = 300 -- 5 minutes

-- Fetch tags from API
local function fetch_tags(callback)
  local rest = require('engram.rest')
  local async = require('engram.async')
  local config = require('engram.config')
  local cfg = config.get()

  -- GET /tag endpoint
  async.http_request('GET', cfg.api_url .. '/tag?limit=1000', {
    timeout = cfg.timeout,
  }, function(err, response)
    if err then
      callback(err, nil)
      return
    end

    if response and response.success and response.data then
      local tags = {}
      for _, tag in ipairs(response.data) do
        table.insert(tags, tag.name)
      end
      callback(nil, tags)
    else
      callback('Invalid response', nil)
    end
  end)
end

-- Get tags (cached)
function M.get_tags(force_refresh)
  local now = os.time()

  if force_refresh or (now - cache_timestamp) > cache_ttl then
    fetch_tags(function(err, tags)
      if not err and tags then
        tag_cache = tags
        cache_timestamp = now
      end
    end)
  end

  return tag_cache
end

-- Omnifunc completion function
function M.omnifunc(findstart, base)
  if findstart == 1 then
    -- Find start of word
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Look for # before cursor
    local start = col
    while start > 0 do
      local char = line:sub(start, start)
      if char == '#' then
        return start -- Return 0-based column
      elseif char:match('[%s,]') then
        break
      end
      start = start - 1
    end

    return -1 -- No completion
  else
    -- Return completions
    local tags = M.get_tags()
    local completions = {}

    for _, tag in ipairs(tags) do
      if tag:lower():find(base:lower(), 1, true) then
        table.insert(completions, {
          word = tag,
          menu = '[Engram]',
          kind = 't',
        })
      end
    end

    return completions
  end
end

-- Setup completion
function M.setup()
  -- Set omnifunc for prompts
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'text', 'markdown', 'vim' },
    callback = function()
      vim.bo.omnifunc = 'v:lua.require("engram.completion").omnifunc'
    end,
  })

  -- Fetch tags on startup
  M.get_tags(true)
end

-- Trigger completion manually
function M.complete_tags()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Check if we're after a #
  if col > 0 and line:sub(col, col) == '#' then
    -- Trigger omni-completion
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true),
      'n',
      false
    )
  end
end

return M
