" engram.nvim - Neovim plugin for Engram personal knowledge management
" Maintainer: cybercat
" Version: 0.1.0

" Prevent loading twice
if exists('g:loaded_engram')
  finish
endif
let g:loaded_engram = 1

" Initialize plugin (setup is done via Lua require('engram').setup())
lua << EOF
-- Plugin is loaded but not initialized
-- User must call require('engram').setup() in their config
EOF
