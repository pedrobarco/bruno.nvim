local M = {}

---Returns the text of a node
---@param node TSNode: the node to get the text for
---@return string: the text of the node
local function get_node_text(node)
	return vim.treesitter.get_node_text(node, 0)
end

---Returns the root node of the buffer
---@param bufnr integer: the buffer number to get the root node for
---@return TSNode: the root node of the buffer
local function get_root_node(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "bru")
	local tree = parser:parse()[1]
	return tree:root()
end

---Checks if a key is disabled
---@param key string: the key to check
---@return boolean: whether the key is disabled
local function is_key_disabled(key)
	return string.sub(key, 1, 1) == "~"
end

---Finds the first node that matches the query
---@param query vim.treesitter.Query: the query to run
---@param node TSNode?: the node to start the search from
---@return TSNode|nil: the first node that matches the query
local function find_first(query, node)
	if node == nil then
		node = get_root_node(0)
	end
	-- TODO: check if iter_matches returns a 1-based index
	for _, matches in query:iter_matches(node, 0) do
		for _, match in ipairs(matches) do
			return match
		end
	end
	return nil
end

---Parses a dictionary node into a lua table
---@param node TSNode: the dictionary node to parse
---@return table: the parsed dictionary
local function parse_dictionary_node(node)
	local dict = {}
	for _, pair in ipairs(node:named_children()) do
		local key_node = pair:named_child(0)
		local value_node = pair:named_child(1)
		if key_node ~= nil and value_node ~= nil then
			local key = get_node_text(key_node)
			local value = get_node_text(value_node)
			if not is_key_disabled(key) then
				dict[key] = value
			end
		end
	end
	return dict
end

---Parses a text block node
---@param node TSNode: the text block node to parse
---@return string: the parsed text block
local function parse_text_block_node(node)
	local text_node = node:named_child(0)
	if text_node == nil then
		return ""
	end

	return get_node_text(text_node)
end

---@alias BruRequestMeta table
BruRequestMeta = {}

---Parses a meta block
---@return BruRequestMeta|nil: the parsed meta block
function M.parse_meta_block()
	local query = vim.treesitter.query.parse("bru", "(meta) @block")
	local meta_node = find_first(query)
	if meta_node == nil then
		return nil
	end

	local dict_node = meta_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return parse_dictionary_node(dict_node)
end

---@class BruRequestHttp
---@field method string: the content type of the body
---@field data table: the data of the body
BruRequestHttp = {}

---Parses an http block
---@return BruRequestHttp|nil: the parsed http block
function M.parse_http_block()
	local query = vim.treesitter.query.parse("bru", "(http) @block")
	local http_node = find_first(query)
	if http_node == nil then
		return nil
	end

	local method_node = http_node:named_child(0)
	if method_node == nil then
		return nil
	end

	local dict_node = http_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	---@type BruRequestHttp
	local http = {
		method = get_node_text(method_node),
		data = parse_dictionary_node(dict_node),
	}

	return http
end

---Parses a graphql vars block
---@return string|nil: the parsed graphql vars block
function M.parse_gql_vars_block()
	local query = vim.treesitter.query.parse("bru", "(bodies (body_graphql_vars) @block)")
	local body_block = find_first(query)
	if body_block == nil then
		return nil
	end

	local content_node = body_block:named_child(1)
	if content_node == nil then
		return nil
	end

	return parse_text_block_node(content_node)
end

---@class BruRequestBody
---@field type string: the content type of the body
---@field data string|table: the data of the body
BruRequestBody = {}

---Parses a body block
---@return BruRequestBody|nil: the parsed body block
function M.parse_body_block()
	local query = vim.treesitter.query.parse("bru", "(bodies (_) @block)")
	local body_block = find_first(query)
	if body_block == nil then
		return nil
	end

	local keyword_node = body_block:named_child(0)
	if keyword_node == nil then
		return nil
	end

	local content_node = body_block:named_child(1)
	if content_node == nil then
		return nil
	end

	---@type BruRequestBody
	local body = {
		type = get_node_text(keyword_node),
		data = {},
	}

	if string.find(body.type, "form") then
		body.data = parse_dictionary_node(content_node)
	else
		body.data = parse_text_block_node(content_node)
	end

	if body.type == "body:graphql" then
		local vars = M.parse_gql_vars_block()
		if vars ~= nil then
			local gql_vars = vim.fn.json_decode(vars)
			body.data = vim.fn.json_encode({ query = body.data, variables = gql_vars })
		else
			body.data = vim.fn.json_encode({ query = body.data })
		end
	end

	return body
end

---@class BruRequestAuth
---@field type string: the type of the auth block
---@field data table: the data of the auth block
BruRequestAuth = {}

---Parses an auth block
---@return BruRequestAuth|nil: the parsed auth block
function M.parse_auth_block()
	local query = vim.treesitter.query.parse("bru", "(auths (_) @block)")
	local auth_block = find_first(query)
	if auth_block == nil then
		return nil
	end

	local keyword_node = auth_block:named_child(0)
	if keyword_node == nil then
		return nil
	end

	local dict_node = auth_block:named_child(1)
	if dict_node == nil then
		return nil
	end

	return {
		type = get_node_text(keyword_node),
		data = parse_dictionary_node(dict_node),
	}
end

---@alias BruRequestHeaders table
BruRequestHeaders = {}

---Parses a headers block
---@return BruRequestHeaders|nil: the parsed headers block
function M.parse_headers_block()
	local query = vim.treesitter.query.parse("bru", "(headers) @block")
	local headers_node = find_first(query)
	if headers_node == nil then
		return nil
	end

	local dict_node = headers_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return parse_dictionary_node(dict_node)
end

---@alias BruRequestQuery table
BruRequestQuery = {}

---Parses a query block
---@return BruRequestQuery|nil: the parsed query block
function M.parse_query_block()
	local query = vim.treesitter.query.parse("bru", "(query) @block")
	local query_node = find_first(query)
	if query_node == nil then
		return nil
	end

	local dict_node = query_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return parse_dictionary_node(dict_node)
end

---@alias BruRequestPathParams table
BruRequestPathParams = {}

---Parses a path params block
---@return BruRequestPathParams|nil: the parsed path params block
function M.parse_path_params_block()
	local query = vim.treesitter.query.parse("bru", "(params (params_path) @block)")
	local query_node = find_first(query)
	if query_node == nil then
		return nil
	end

	local dict_node = query_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return parse_dictionary_node(dict_node)
end

---@alias BruRequestQueryParams table
BruRequestQueryParams = {}

---Parses a query params block
---@return BruRequestQueryParams|nil: the parsed query params block
function M.parse_query_params_block()
	local query = vim.treesitter.query.parse("bru", "(params (params_query) @block)")
	local query_node = find_first(query)
	if query_node == nil then
		return nil
	end

	local dict_node = query_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return parse_dictionary_node(dict_node)
end

---An HTTP request
---@class BruRequest
---@field meta BruRequestMeta: the meta block
---@field http BruRequestHttp: the http block
---@field body BruRequestBody|nil: the body block
---@field headers BruRequestHeaders|nil: the headers block
---@field query BruRequestQuery|nil: the query block
---@field auth BruRequestAuth|nil: the auth block
BruRequest = {}

---Parses a request
---@return BruRequest: the parsed request
function M.parse_request()
	local request = {}

	local meta = M.parse_meta_block()
	if meta == nil then
		error("No meta block found")
	end
	request.meta = meta

	local http = M.parse_http_block()
	if http == nil then
		error("No http block found")
	end
	request.http = http

	request.body = M.parse_body_block()
	request.headers = M.parse_headers_block()
	request.query = M.parse_query_block()
	request.auth = M.parse_auth_block()

	local path_params = M.parse_path_params_block()
	if path_params ~= nil then
		for k, v in pairs(path_params) do
			request.http.data.url = request.http.data.url:gsub(":" .. k, v)
		end
	end

	local query_params = M.parse_query_params_block()
	if query_params ~= nil then
		for k, v in pairs(query_params) do
			if request.query[k] ~= nil then
				request.query[k] = request.query[k]:gsub(":" .. k, v)
			end
		end
	end

	return request
end

return M
