local M = {}

local client = require("bruno.client")

local function request()
	client.request()
end

function M.init(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoRun", request, { desc = "Run bruno request" })
end

return M
