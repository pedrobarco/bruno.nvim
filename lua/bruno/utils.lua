local M = {}

---Wrapper around vim.inspect
---@param v any
M.P = function(v)
	print(vim.inspect(v))
end

---Wrapper around vim.treesitter.get_node_text
---@param node TSNode
---@param content string?
M.T = function(node, content)
	local source = content or 0
	local text = vim.treesitter.get_node_text(node, source)
	M.P(text)
end

---Check if the current session has a UI
---@return boolean
M.has_ui = function()
	return #vim.api.nvim_list_uis() ~= 0
end

return M
