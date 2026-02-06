# engram.nvim

Neovim plugin for [Engram](https://github.com/cybercat/engram) - A personal knowledge management system.

## Features

- 📝 **Quick Capture** - Capture thoughts, notes, and code snippets directly from Neovim
- 🔍 **Search** - Full-text search across all your captures
- 🏷️ **Auto-tagging** - Automatically extract tags from `#hashtags`
- 🌐 **Context-aware** - Includes file path, line number, and git branch
- ⚡ **Async** - Non-blocking HTTP requests using vim.loop
- 🎨 **Clean UI** - Native Neovim UI with floating windows
- 🧠 **Memory Management** - Create and manage long-term memories

## Requirements

- Neovim >= 0.8.0
- [Engram backend](https://github.com/cybercat/engram) running on localhost:3000
- `curl` (for HTTP requests)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'cybercat/engram.nvim',
  config = function()
    require('engram').setup({
      api_url = 'http://localhost:3000',
      include_context = true,
      auto_tag = true,
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'cybercat/engram.nvim',
  config = function()
    require('engram').setup()
  end,
}
```

## Configuration

Default configuration:

```lua
require('engram').setup({
  -- API endpoint
  api_url = 'http://localhost:3000',
  
  -- Source identifier for captures from Neovim
  source = 'NVIM',
  
  -- Request timeout (ms)
  timeout = 30000,
  
  -- Include context metadata (file, line, git branch)
  include_context = true,
  
  -- Auto-extract tags from #hashtags
  auto_tag = true,
  
  -- Enable debug logging
  debug = false,
  
  -- Keymaps
  keymaps = {
    capture_visual = '<leader>ec',  -- Capture visual selection
    capture_line = '<leader>el',    -- Capture current line
    capture_prompt = '<leader>ep',  -- Capture with prompt
    list_captures = '<leader>eL',   -- List recent captures
    search_captures = '<leader>es', -- Search captures
  },
  
  -- UI options
  ui = {
    use_telescope = true,          -- Use Telescope for lists (TODO)
    notification_style = 'native', -- 'native' or 'nvim-notify'
  },
})
```

## Usage

### Capture Commands

**Visual Selection:**
```vim
" Select text in visual mode, then:
:EngramCaptureVisual
" Or use keymap: <leader>ec
```

**Current Line:**
```vim
:EngramCaptureLine
" Or: <leader>el
```

**With Prompt:**
```vim
:EngramCapture
" Or: <leader>ep
```

**With Tags:**
```lua
-- In your capture, use #hashtags
-- Example: "Fix auth bug #bug #urgent"
-- Will auto-extract tags: ["bug", "urgent"]
```

### Browse & Search

**List Recent Captures:**
```vim
:EngramList
" Or: <leader>eL
```

**Search Captures:**
```vim
:EngramSearch
" Or: <leader>es
```

### Memory Management

**Create Memory:**
```vim
:EngramMemoryCreate
```

**Create Core Memory (permanent):**
```vim
:EngramMemoryCore
```

**List Memories:**
```vim
:EngramMemoryList
```

### Health Check

```vim
:EngramHealth
```

## Context Metadata

When `include_context = true`, captures automatically include:

```lua
{
  content = "Your captured text",
  source = "NVIM",
  tags = ["auto", "extracted"],
  metadata = {
    file = "/path/to/file.lua",
    line = 42,
    column = 15,
    filetype = "lua",
    git_branch = "feature/new-thing",
    cwd = "/path/to/project"
  }
}
```

## API

You can also use the plugin API directly:

```lua
local engram = require('engram')

-- Capture programmatically
engram.capture_prompt()
engram.capture_line()

-- List and search
engram.list()
engram.search()

-- Memories
engram.create_memory()
engram.list_memories()

-- Health
engram.health()
```

## Architecture

```
engram-nvim/
├── lua/engram/
│   ├── init.lua         # Main plugin entry
│   ├── config.lua       # Configuration management
│   ├── async.lua        # Async job control (vim.loop)
│   ├── rest.lua         # REST API client
│   ├── commands.lua     # Command implementations
│   ├── ui/              # UI components
│   │   ├── prompts.lua  # User input prompts
│   │   ├── renderer.lua # Display formatting
│   └── util/            # Utility functions
└── plugin/
    └── engram.vim       # Plugin initialization
```

## Roadmap

- [ ] Telescope integration for better UX
- [ ] Treesitter integration for code context
- [ ] Auto-capture TODO comments
- [ ] Memory search integration
- [ ] Tag completion
- [ ] Offline queue (capture when API is down)
- [ ] Sync status indicator

## Development

```bash
# Clone the repo
git clone https://github.com/cybercat/engram-nvim.git

# Symlink to your Neovim config for testing
ln -s $(pwd)/engram-nvim ~/.local/share/nvim/site/pack/dev/start/engram-nvim

# Test in Neovim
nvim -c "lua require('engram').setup()"
```

## License

MIT

## Credits

Built for [Engram](https://github.com/cybercat/engram) - Personal AI assistant and knowledge management system.
