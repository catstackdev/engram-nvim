-- Configuration management for engram.nvim
local M = {}

-- Default configuration
M.defaults = {
	api_url = "http://localhost:3000",
	source = "NVIM",
	timeout = 30000, -- 30 seconds
	include_context = true,
	auto_tag = true,
	debug = false,
	keymaps = {
		capture_visual = "<leader>ec",
		capture_line = "<leader>el",
		capture_prompt = "<leader>ep",
		list_captures = "<leader>eL",
		search_captures = "<leader>es",
	},
	ui = {
		use_telescope = true,
		notification_style = "native", -- 'native' or 'nvim-notify'
	},
}

-- Current configuration (merged defaults + user config)
M.options = vim.deepcopy(M.defaults)

-- Setup function called by user
function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})

	-- Validate configuration
	if type(M.options.api_url) ~= "string" then
		vim.notify("engram.nvim: api_url must be a string", vim.log.levels.ERROR)
	end

	return M.options
end

-- Get current config
function M.get()
	return M.options
end

return M
