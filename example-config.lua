-- Example configuration for engram.nvim
-- Copy this to your Neovim config and customize

return {
  'cybercat/engram.nvim',
  config = function()
    require('engram').setup({
      -- API endpoint (change if your backend runs on different port)
      api_url = 'http://localhost:3000',

      -- Source identifier for captures from Neovim
      source = 'NVIM',

      -- Request timeout in milliseconds
      timeout = 30000,

      -- Include context metadata (file path, line number, git branch)
      include_context = true,

      -- Auto-extract tags from #hashtags in content
      auto_tag = true,

      -- Enable debug logging
      debug = false,

      -- Keymaps configuration
      keymaps = {
        capture_visual = '<leader>ec', -- Capture visual selection
        capture_line = '<leader>el', -- Capture current line
        capture_prompt = '<leader>ep', -- Capture with prompt
        list_captures = '<leader>eL', -- List recent captures
        search_captures = '<leader>es', -- Search captures
      },

      -- UI preferences
      ui = {
        use_telescope = true, -- Use Telescope for better UX (TODO)
        notification_style = 'native', -- 'native' or 'nvim-notify'
      },
    })

    -- Optional: Create custom keymaps
    -- vim.keymap.set('n', '<leader>em', function()
    --   require('engram').create_memory({ is_core = true })
    -- end, { desc = 'Engram: Create core memory' })
  end,
}

-- Alternative minimal config:
-- require('engram').setup()  -- Uses all defaults
