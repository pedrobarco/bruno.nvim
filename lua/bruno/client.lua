local M = {}

local parser = require("bruno.parser")

local P = function(v)
	print(vim.inspect(v))
	return v
end

local T = function(node)
	P(vim.treesitter.get_node_text(node, 0))
end

function M.request()
	local http_block = parser.get_http_block()
	T(http_block)
end

return M
