local M = {}

---Returns the root node of the buffer
---@param bufnr number: the buffer number to get the root node for
---@return TSNode: the root node of the buffer
local function get_root_node(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "bru")
	local tree = parser:parse()[1]
	return tree:root()
end

---Finds the first node that matches the query
---@param query vim.treesitter.Query: the query to run
---@param node TSNode?: the node to start the search from
---@return TSNode[]|nil: the first node that matches the query
local function find_first(query, node)
	if node == nil then
		node = get_root_node(0)
	end

	-- run a treesitter query to find the first match
	-- TODO: check if iter_matches returns a 1-based index
	for _, matches in query:iter_matches(node, 0) do
		for _, match in ipairs(matches) do
			return match
		end
	end

	return nil
end

function M.get_http_block()
	local query = vim.treesitter.query.parse("bru", "(http) @block")
	return find_first(query)
end

return M
