# engram.nvim

**Feature-complete** Neovim plugin for [Engram](https://github.com/cybercat/engram) - A personal knowledge management system.

## ✨ Features

### Core Capture
- 📝 **Quick Capture** - Capture thoughts, notes, and code snippets from Neovim
- 🔍 **Full-Text Search** - Search across all your captures with relevance ranking
- 🏷️ **Auto-tagging** - Automatically extract tags from `#hashtags`
- 🌐 **Context-aware** - Includes file path, line number, and git branch

### Advanced Features
- 🌳 **Treesitter Integration** - Capture function/class context automatically
- 🔭 **Telescope Integration** - Beautiful pickers for browsing and searching
- 📡 **Offline Queue** - Capture even when API is down, sync later
- ✅ **TODO Auto-capture** - Automatically capture TODO comments on save
- 🏁 **Tag Completion** - Auto-complete tags from your knowledge base
- 🧠 **Memory Management** - Create and manage long-term memories
- ⚡ **Async Everything** - Non-blocking HTTP requests using vim.loop

## 📦 Requirements

- Neovim >= 0.8.0
- [Engram backend](https://github.com/cybercat/engram) running
- `curl` (for HTTP requests)

### Optional Dependencies
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Better UI (recommended)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Enhanced context

## 🚀 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  'cybercat/engram.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- Optional but recommended
    'nvim-treesitter/nvim-treesitter', -- Optional for enhanced context
  },
  config = function()
    require('engram').setup({
      api_url = 'http://localhost:3000',
      enhanced_context = true, -- Use treesitter
      offline_queue = true, -- Enable offline mode
      auto_capture_todos = false, -- Auto-capture TODOs on save
      tag_completion = true, -- Enable tag completion
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'cybercat/engram.nvim',
  requires = {
    'nvim-telescope/telescope.nvim', -- Optional
    'nvim-treesitter/nvim-treesitter', -- Optional
  },
  config = function()
    require('engram').setup()
  end,
}
```

## ⚙️ Configuration

### Default Configuration

```lua
require('engram').setup({
  -- API Configuration
  api_url = 'http://localhost:3000', -- Engram backend URL
  source = 'NVIM', -- Source identifier
  timeout = 30000, -- Request timeout (ms)
  
  -- Context Options
  include_context = true, -- Include file/line/git metadata
  enhanced_context = true, -- Use treesitter for function/class context
  
  -- Feature Toggles
  auto_tag = true, -- Auto-extract #hashtags as tags
  offline_queue = true, -- Queue captures when offline
  auto_capture_todos = false, -- Auto-capture TODO comments on save
  tag_completion = true, -- Enable tag completion
  debug = false, -- Debug logging
  
  -- Keymaps
  keymaps = {
    capture_visual = '<leader>ec', -- Capture visual selection
    capture_line = '<leader>el', -- Capture current line
    capture_prompt = '<leader>ep', -- Capture with prompt
    list_captures = '<leader>eL', -- List recent captures
    search_captures = '<leader>es', -- Search captures
    sync_queue = '<leader>eq', -- Sync offline queue
  },
  
  -- UI Options
  ui = {
    use_telescope = true, -- Use Telescope for lists/search
    notification_style = 'native', -- 'native' or 'nvim-notify'
  },
})
```

## 📖 Usage

### Basic Capture

**Visual Selection:**
```vim
" 1. Select text in visual mode (v, V, or Ctrl-v)
" 2. Press <leader>ec
" Or run: :EngramCaptureVisual
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
" Type your note and press Enter
```

**With Tags:**
```lua
-- Use #hashtags in your capture:
"Fix authentication bug #urgent #backend"
-- Tags auto-extracted: ["urgent", "backend"]
```

### Browse & Search

**List Recent Captures (Telescope):**
```vim
:EngramList
" Or: <leader>eL
" Use j/k to navigate, Enter to view details
```

**Search Captures:**
```vim
:EngramSearch
" Or: <leader>es
" Type search query, press Enter
```

### Memory Management

**Create Working Memory:**
```vim
:EngramMemoryCreate
```

**Create Core Memory (Permanent):**
```vim
:EngramMemoryCore
```

**List Memories (Telescope):**
```vim
:EngramMemoryList
```

### Offline Mode

**Check Queue Status:**
```vim
:EngramQueueStatus
```

**Sync Queued Items:**
```vim
:EngramQueueSync
" Or: <leader>eq
```

When the API is unavailable, captures are automatically queued and can be synced later.

### TODO Auto-Capture

**Enable in Config:**
```lua
require('engram').setup({
  auto_capture_todos = true,
})
```

**Manual Scan:**
```vim
:EngramScanTodos
```

Supported patterns:
```lua
-- Lua: -- TODO: Fix this
// JavaScript/TypeScript: // TODO: Add validation
# Python/Shell: # TODO: Refactor
/* C/C++: // TODO: Optimize */
" Vim: " TODO: Document this
```

### Tag Completion

**Auto-complete Tags:**
```vim
" In insert mode, type:
I fixed the bug #
" Then press Ctrl-x Ctrl-o for omni-completion
" Tags from your knowledge base will appear
```

## 🌳 Context Metadata

### Basic Context (Default)

```json
{
  "content": "Fix authentication bug",
  "source": "NVIM",
  "tags": ["bug", "auth"],
  "metadata": {
    "file": "/Users/you/project/auth.ts",
    "line": 42,
    "column": 15,
    "filetype": "typescript",
    "git_branch": "feature/auth-fix",
    "cwd": "/Users/you/project"
  }
}
```

### Enhanced Context (with Treesitter)

```json
{
  "content": "Optimize database query",
  "metadata": {
    "file": "/Users/you/project/db.ts",
    "line": 156,
    "function_name": "fetchUsers",
    "class_name": "DatabaseService",
    "surrounding_code": "...", // 3 lines before/after
    "code_start_line": 153,
    "code_end_line": 159
  }
}
```

## 🎨 Telescope Integration

When Telescope is installed and enabled, you get:

- **Beautiful Pickers** - Fuzzy finding for captures/memories
- **Live Preview** - See full content while browsing
- **Better Navigation** - Standard Telescope keymaps
- **Faster Search** - Incremental filtering

**Telescope Commands:**
- `:EngramList` - Browse with preview
- `:EngramSearch` - Search with live results
- `:EngramMemoryList` - Memory picker

## 📡 Offline Queue

Captures are queued when API is unavailable:

```vim
" Capture while offline
:EngramCapture
# API unavailable - Queued for sync (3 pending)

" Check queue
:EngramQueueStatus
# Shows all queued items

" Sync when back online
:EngramQueueSync
# Or: <leader>eq
# Synced 3/3 items
```

Queue is persisted to disk at `~/.local/share/nvim/engram-queue.json`

## 🔧 Advanced Usage

### Programmatic API

```lua
local engram = require('engram')

-- Capture
engram.capture_line()
engram.capture_prompt()

-- Browse
engram.list()
engram.search()

-- Memories
engram.create_memory()
engram.list_memories()

-- Queue
engram.sync_queue()
engram.queue_status()

-- TODOs
engram.scan_todos()

-- Health
engram.health()
```

### Custom Keymaps

```lua
-- In your config
vim.keymap.set('n', '<C-n>', function()
  require('engram').capture_prompt()
end, { desc = 'Quick capture' })

vim.keymap.set('n', '<leader>ft', function()
  require('engram').scan_todos()
end, { desc = 'Find TODOs' })
```

### Autocommands

```lua
-- Auto-sync queue on VimEnter
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    require('engram').sync_queue()
  end,
})

-- Capture on specific events
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.md',
  callback = function()
    -- Auto-capture markdown saves
  end,
})
```

## 📊 Commands Reference

### Capture
| Command | Description |
|---------|-------------|
| `:EngramCapture` | Prompt for capture |
| `:EngramCaptureLine` | Capture current line |
| `:EngramCaptureVisual` | Capture visual selection |

### Browse
| Command | Description |
|---------|-------------|
| `:EngramList` | List recent captures |
| `:EngramSearch` | Search captures |

### Memory
| Command | Description |
|---------|-------------|
| `:EngramMemoryCreate` | Create working memory |
| `:EngramMemoryCore` | Create core memory |
| `:EngramMemoryList` | List memories |

### Queue
| Command | Description |
|---------|-------------|
| `:EngramQueueSync` | Sync offline queue |
| `:EngramQueueStatus` | Show queue status |

### Utility
| Command | Description |
|---------|-------------|
| `:EngramScanTodos` | Scan buffer for TODOs |
| `:EngramHealth` | Check API health |

## 🏗️ Architecture

```
engram-nvim/
├── lua/engram/
│   ├── init.lua         # Main entry, setup()
│   ├── config.lua       # Configuration management
│   ├── async.lua        # Async job control (vim.loop)
│   ├── rest.lua         # REST API client
│   ├── commands.lua     # Command implementations
│   ├── telescope.lua    # Telescope integration
│   ├── treesitter.lua   # Treesitter integration
│   ├── queue.lua        # Offline queue
│   ├── completion.lua   # Tag completion
│   ├── todo.lua         # TODO auto-capture
│   ├── ui/              # UI components
│   │   ├── prompts.lua
│   │   ├── renderer.lua
│   │   ├── windows.lua
│   │   └── buffers.lua
│   └── util/
│       └── init.lua     # Utilities
└── plugin/
    └── engram.vim       # Plugin initialization
```

**Design Principles:**
- ✅ **Clean Separation** - REST, UI, commands are independent
- ✅ **Async First** - Non-blocking via vim.loop
- ✅ **No Dependencies** - Optional integrations only
- ✅ **Extensible** - Easy to add new features

## 🐛 Troubleshooting

### Connection Issues

```vim
" Check API health
:EngramHealth

" If failed, verify backend is running:
# Terminal: lsof -ti:3000
```

### Telescope Not Working

```vim
" Verify Telescope is installed
:checkhealth telescope

" Force native UI
lua require('engram').setup({ ui = { use_telescope = false } })
```

### Queue Not Syncing

```vim
" Check queue status
:EngramQueueStatus

" View queue file
:!cat ~/.local/share/nvim/engram-queue.json

" Clear queue if corrupted
:lua require('engram.queue').clear()
```

### Tags Not Completing

```vim
" Manually trigger completion
" In insert mode: Ctrl-x Ctrl-o

" Refresh tag cache
:lua require('engram.completion').get_tags(true)
```

## 📚 Documentation

- **README.md** - User guide (this file)
- **QUICKSTART.md** - 5-minute getting started
- **DEVELOPMENT.md** - Architecture and dev guide
- **example-config.lua** - Configuration examples

## 🎯 Roadmap

- [x] Core capture functionality
- [x] Telescope integration
- [x] Treesitter integration
- [x] Offline queue
- [x] Tag completion
- [x] TODO auto-capture
- [ ] Fuzzy tag search in Telescope
- [ ] Export captures to markdown
- [ ] Sync status indicator in statusline
- [ ] Conflict resolution for offline edits

## 🤝 Contributing

Contributions are welcome! See `DEVELOPMENT.md` for architecture details.

## 📄 License

MIT

## 💖 Credits

Built for [Engram](https://github.com/cybercat/engram) - Personal AI assistant and knowledge management system.
