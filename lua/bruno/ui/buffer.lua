---@class Buffer
local Buffer = {}
Buffer.__index = Buffer
Buffer.name = "bruno_nvim_response"

---Create a new buffer
---@return Buffer: the buffer
function Buffer:new()
	setmetatable({}, self)

	self.number = vim.api.nvim_create_buf(true, true)
	self.name = Buffer.name

	local opts = { buf = self.number }

	vim.api.nvim_buf_set_name(self.number, self.name)
	vim.api.nvim_set_option_value("ft", "bruResponse", opts)
	vim.api.nvim_set_option_value("buftype", "nofile", opts)
	vim.api.nvim_set_option_value("modifiable", false, opts)

	return self
end

---Create a buffer from a buffer number
---@param bufnr number: the buffer number
---@return Buffer: the buffer
function Buffer:from_bufnr(bufnr)
	setmetatable({}, self)

	self.number = bufnr
	self.name = Buffer.name

	return self
end

---Write content to the buffer
---@param content string[]: the content to write
function Buffer:write(content)
	local opts = { buf = self.number }
	vim.api.nvim_set_option_value("modifiable", true, opts)
	vim.api.nvim_buf_set_lines(self.number, 0, -1, false, content)
	vim.api.nvim_set_option_value("modifiable", false, opts)
end

---Clear the buffer
function Buffer:clear()
	Buffer:write({})
end

---Show the buffer
function Buffer:show()
	vim.cmd("vertical split")
	vim.cmd("wincmd r")
	vim.api.nvim_win_set_buf(0, self.number)
end

return Buffer
