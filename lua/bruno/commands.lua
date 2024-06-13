local M = {}

local parser = require("bruno.parser")
local client = require("bruno.client")
local utils = require("bruno.utils")

local function request()
	local req = parser.parse_request()

	--TODO: pick environment file
	local env = {}

	local res = client.bru_request(req, env)
	utils.P(res)
end

function M.init(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoRun", request, { desc = "Run bruno request" })
end

return M
