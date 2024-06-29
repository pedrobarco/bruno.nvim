local M = {}

local Buffer = require("bruno.ui.buffer")

local function find_buf()
	local bufnr = nil
	for _, id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(id):find(Buffer.name) then
			bufnr = id
			break
		end
	end
	return bufnr and Buffer:from_bufnr(bufnr) or Buffer:new()
end

---Display the result
---@param result CurlResponse: the result to display
function M.display_result(result)
	local buf = find_buf()
	local content = {}

	for line in vim.inspect(result):gmatch("[^\r\n]+") do
		table.insert(content, line)
	end

	buf:write(content)
	buf:show()
	-- local bufnr = rest_ui.get_or_create_buf()
	-- rest_ui.write_res(bufnr, result)
end

---Display the command
---@param cmd string: the command to display
function M.display_cmd(cmd)
	local buf = find_buf()
	local content = {}

	for line in vim.inspect(cmd):gmatch("[^\r\n]+") do
		table.insert(content, line)
	end

	buf:write(content)
	buf:show()
end

return M
