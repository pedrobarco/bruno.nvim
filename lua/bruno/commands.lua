local M = {}

local parser = require("bruno.parser")
local client = require("bruno.client")
local utils = require("bruno.utils")

local function request()
	local raw = parser.parse_request()

	---@type Request
	local req = {
		url = raw.http.url,
		method = raw.http.method,
		body = raw.body,
		form = raw.form,
	}

	-- TODO: parse auth block and configure headers

	local res = client.request(req)
	utils.P(res)
end

function M.init(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoRun", request, { desc = "Run bruno request" })
end

return M
