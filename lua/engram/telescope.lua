-- Telescope integration for engram.nvim
local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  return nil
end

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local rest = require('engram.rest')
local util = require('engram.util')

local M = {}

-- Create telescope picker for captures
function M.captures(opts)
  opts = opts or {}

  rest.list_captures({ limit = opts.limit or 50 }, function(err, result)
    if err then
      util.notify_error('Failed to list captures: ' .. err)
      return
    end

    if not result or not result.items or #result.items == 0 then
      util.notify_warn('No captures found')
      return
    end

    pickers
      .new(opts, {
        prompt_title = 'Engram Captures',
        finder = finders.new_table({
          results = result.items,
          entry_maker = function(entry)
            local display = string.format(
              '[%s] %s',
              entry.source,
              util.truncate(entry.content, 80)
            )

            if entry.tags and #entry.tags > 0 then
              display = display .. ' | ' .. table.concat(entry.tags, ', ')
            end

            return {
              value = entry,
              display = display,
              ordinal = entry.content,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
          title = 'Capture Details',
          define_preview = function(self, entry)
            local lines = {
              'ID: ' .. entry.value.id,
              'Source: ' .. entry.value.source,
              'Created: ' .. util.format_time(entry.value.createdAt or ''),
              '',
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
              '',
              entry.value.content,
              '',
            }

            if entry.value.tags and #entry.value.tags > 0 then
              table.insert(lines, 'Tags: ' .. table.concat(entry.value.tags, ', '))
              table.insert(lines, '')
            end

            if entry.value.metadata then
              table.insert(lines, 'Metadata:')
              -- Handle metadata (might be userdata from JSON)
              local metadata = entry.value.metadata
              if type(metadata) == 'table' then
                for key, value in pairs(metadata) do
                  table.insert(lines, '  ' .. key .. ': ' .. tostring(value))
                end
              else
                -- If userdata, try to decode or just show type
                table.insert(lines, '  Type: ' .. type(metadata))
              end
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            -- Open capture in floating window
            local commands = require('engram.commands')
            commands.show_capture_detail(selection.value)
          end)
          return true
        end,
      })
      :find()
  end)
end

-- Search captures with Telescope
function M.search(opts)
  opts = opts or {}

  -- Get search query
  vim.ui.input({ prompt = 'Search: ' }, function(query)
    if not query or query == '' then
      return
    end

    rest.search_captures(query, { limit = opts.limit or 50 }, function(err, results)
      if err then
        util.notify_error('Search failed: ' .. err)
        return
      end

      if not results or #results == 0 then
        util.notify_warn('No results found')
        return
      end

      pickers
        .new(opts, {
          prompt_title = 'Search Results: ' .. query,
          finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
              local display = string.format(
                '[%s] %s',
                entry.source,
                util.truncate(entry.content, 80)
              )

              if entry.tags and #entry.tags > 0 then
                display = display .. ' | ' .. table.concat(entry.tags, ', ')
              end

              return {
                value = entry,
                display = display,
                ordinal = entry.content,
              }
            end,
          }),
          sorter = conf.generic_sorter(opts),
          previewer = previewers.new_buffer_previewer({
            title = 'Capture Details',
            define_preview = function(self, entry)
              local lines = {
                'ID: ' .. entry.value.id,
                'Source: ' .. entry.value.source,
                'Relevance: ' .. string.format('%.2f', entry.value.relevance or 0),
                'Created: ' .. util.format_time(entry.value.createdAt or ''),
                '',
                '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                '',
                entry.value.content,
              }

              if entry.value.tags and #entry.value.tags > 0 then
                table.insert(lines, '')
                table.insert(lines, 'Tags: ' .. table.concat(entry.value.tags, ', '))
              end

              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            end,
          }),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local commands = require('engram.commands')
              commands.show_capture_detail(selection.value)
            end)
            return true
          end,
        })
        :find()
    end)
  end)
end

-- Memories picker
function M.memories(opts)
  opts = opts or {}

  rest.list_memories({ limit = opts.limit or 50 }, function(err, results)
    if err then
      util.notify_error('Failed to list memories: ' .. err)
      return
    end

    if not results or #results == 0 then
      util.notify_warn('No memories found')
      return
    end

    pickers
      .new(opts, {
        prompt_title = 'Engram Memories',
        finder = finders.new_table({
          results = results,
          entry_maker = function(entry)
            local mem_type = entry.isCore and '[Core]' or '[Work]'
            local display = string.format('%s %s', mem_type, util.truncate(entry.content, 70))

            return {
              value = entry,
              display = display,
              ordinal = entry.content,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
          title = 'Memory Details',
          define_preview = function(self, entry)
            local lines = {
              'ID: ' .. entry.value.id,
              'Type: ' .. (entry.value.isCore and 'Core Memory' or 'Working Memory'),
              'Created: ' .. util.format_time(entry.value.createdAt or ''),
              '',
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
              '',
              entry.value.content,
            }

            if entry.value.importance then
              table.insert(lines, '')
              table.insert(lines, 'Importance: ' .. tostring(entry.value.importance))
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        }),
      })
      :find()
  end)
end

return M
