P = function(v)
	print(vim.inspect(v))
	return v
end

T = function(node)
	P(vim.treesitter.get_node_text(node, 0))
end

local M = {}

local function get_http_block()
	-- get the parser for the current buffer
	local parser = vim.treesitter.get_parser(0, "bru")
	local tree = parser:parse()[1]
	local root = tree:root()

	-- run a treesitter query to find the http block
	-- TODO: check if iter_matches returns a 1-based index
	local query = vim.treesitter.query.parse("bru", "(http) @block")
	for _, matches in query:iter_matches(root, 0) do
		for _, node in ipairs(matches) do
			return node
		end
	end
	return nil
end

function M.request()
	local http_block = get_http_block()
	T(http_block)
end

return M
