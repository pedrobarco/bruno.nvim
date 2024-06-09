local M = {}

---Wrapper around vim.inspect
---@param v any
M.P = function(v)
	print(vim.inspect(v))
end

---Wrapper around vim.treesitter.get_node_text
---@param node TSNode
---@return string
M.T = function(node)
	local text = vim.treesitter.get_node_text(node, 0)
	-- TODO: comment this out
	M.P(text)
	return text
end

return M
