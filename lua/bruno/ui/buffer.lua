local M = {}

local buf_name = "bruno_nvim_response"

local Buffer = {}
Buffer.__index = Buffer

function Buffer:new()
	setmetatable({}, self)

	self.number = vim.api.nvim_create_buf(true, true)
	self.name = buf_name

	local opts = { buf = self.number }

	vim.api.nvim_buf_set_name(self.number, self.name)
	vim.api.nvim_set_option_value("ft", "bruResponse", opts)
	vim.api.nvim_set_option_value("buftype", "nofile", opts)
	vim.api.nvim_set_option_value("modifiable", false, opts)

	return self
end

function Buffer:from_bufnr(bufnr)
	setmetatable({}, self)

	self.number = bufnr
	self.name = buf_name

	return self
end

function Buffer:write(content)
	local opts = { buf = self.number }
	vim.api.nvim_set_option_value("modifiable", true, opts)
	vim.api.nvim_buf_set_lines(self.number, 0, -1, false, content)
	vim.api.nvim_set_option_value("modifiable", false, opts)
end

function Buffer:clear()
	Buffer:write({})
end

function Buffer:show()
	vim.cmd("vertical split")
	vim.cmd("wincmd r")
	vim.api.nvim_win_set_buf(0, self.number)
end

local function find_buf()
	local bufnr = nil
	for _, id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(id):find(buf_name) then
			bufnr = id
			break
		end
	end
	return bufnr and Buffer:from_bufnr(bufnr) or Buffer:new()
end

function M.display_result(result)
	local buf = find_buf()
	local content = {}

	for line in vim.inspect(result):gmatch("[^\r\n]+") do
		table.insert(content, line)
	end

	buf:write(content)
	buf:show()
end

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
