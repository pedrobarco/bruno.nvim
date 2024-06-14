local M = {}

local parser = require("bruno.parser")
local client = require("bruno.client")

local function request()
	local bufnr = vim.api.nvim_get_current_buf()
	local line_range = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(line_range, "\n")

	local req = parser.parse_request(content)

	--TODO: find "bru.json" based on "request.bru" file path
	--TODO: pick environment file
	local env = {}

	local res = client.bru_request(req, env)
	return res
end

function M.init(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoRun", request, { desc = "Run bruno request" })
end

return M
