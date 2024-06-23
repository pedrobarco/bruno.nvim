local Buffer = {}
Buffer.__index = Buffer
Buffer.name = "bruno_nvim_response"

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

function Buffer:from_bufnr(bufnr)
	setmetatable({}, self)

	self.number = bufnr
	self.name = Buffer.name

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

return Buffer
