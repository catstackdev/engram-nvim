-- UI prompts for user input
local util = require('engram.util')
local M = {}

-- Prompt for capture content
function M.capture_prompt(callback, default_text)
  vim.ui.input({
    prompt = 'Capture: ',
    default = default_text or '',
  }, function(input)
    if not input or input == '' then
      util.notify_warn('Capture cancelled')
      return
    end
    callback(input)
  end)
end

-- Prompt for tags (comma-separated)
function M.tags_prompt(callback, default_tags)
  local default_str = default_tags and table.concat(default_tags, ', ') or ''

  vim.ui.input({
    prompt = 'Tags (comma-separated): ',
    default = default_str,
  }, function(input)
    if not input or input == '' then
      callback({})
      return
    end

    -- Parse comma-separated tags
    local tags = {}
    for tag in string.gmatch(input, '([^,]+)') do
      table.insert(tags, vim.trim(tag))
    end
    callback(tags)
  end)
end

-- Prompt for search query
function M.search_prompt(callback)
  vim.ui.input({
    prompt = 'Search: ',
  }, function(input)
    if not input or input == '' then
      util.notify_warn('Search cancelled')
      return
    end
    callback(input)
  end)
end

-- Confirm dialog
function M.confirm(message, callback)
  vim.ui.select({ 'Yes', 'No' }, {
    prompt = message,
  }, function(choice)
    callback(choice == 'Yes')
  end)
end

return M
