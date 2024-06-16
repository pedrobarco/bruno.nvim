local M = {}

local lang = "bru"

---Parses the content as a tree and returns the root node
---@param content string: the content to parse
---@return TSNode: the root node of the parsed tree
local function parse_content(content)
	local parser = vim.treesitter.get_string_parser(content, lang)
	local tree = parser:parse()[1]
	return tree:root()
end

---Checks if a key is disabled
---@param key string: the key to check
---@return boolean: whether the key is disabled
local function is_key_disabled(key)
	return key:sub(1, 1) == "~"
end

---A bru parser
---@class Parser
---@field content string: the content to parse
---@field lang string: the language to parse
---@field root TSNode: the root node of the parsed tree
Parser = {}
Parser.__index = Parser

---Creates a new parser
---@param content string: the content to parse
---@return Parser: the new parser
function Parser:new(content)
	local parser = setmetatable({}, self)

	parser.content = content
	parser.lang = lang
	parser.root = parse_content(content)

	return parser
end

---Returns the text of a node
---@param node TSNode: the node to get the text for
---@return string: the text of the node
function Parser:get_node_text(node)
	return vim.treesitter.get_node_text(node, self.content)
end

---Finds the first node that matches the query
---@param query vim.treesitter.Query: the query to run
---@return TSNode|nil: the first node that matches the query
function Parser:find_first(query)
	for _, matches in query:iter_matches(self.root, self.content) do
		for _, match in ipairs(matches) do
			return match
		end
	end
	return nil
end

---Parses a dictionary node into a lua table
---@param node TSNode: the dictionary node to parse
---@return table: the parsed dictionary
function Parser:parse_dictionary_node(node)
	local dict = {}
	for _, pair in ipairs(node:named_children()) do
		local key_node = pair:named_child(0)
		local value_node = pair:named_child(1)
		if key_node and value_node then
			local key = self:get_node_text(key_node)
			local value = self:get_node_text(value_node)
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
function Parser:parse_text_block_node(node)
	local text_node = node:named_child(0)
	if text_node == nil then
		return ""
	end
	return self:get_node_text(text_node)
end

---@alias BruRequestMeta table
BruRequestMeta = {}

---Parses a meta block
---@return BruRequestMeta|nil: the parsed meta block
function Parser:parse_meta_block()
	local query = vim.treesitter.query.parse(lang, "(meta) @block")
	local meta_node = self:find_first(query)
	if meta_node == nil then
		return nil
	end

	local dict_node = meta_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return self:parse_dictionary_node(dict_node)
end

---@class BruRequestHttp
---@field method string: the content type of the body
---@field data table: the data of the body
BruRequestHttp = {}

---Parses an http block
---@return BruRequestHttp|nil: the parsed http block
function Parser:parse_http_block()
	local query = vim.treesitter.query.parse(lang, "(http) @block")
	local http_node = self:find_first(query)
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
		method = self:get_node_text(method_node),
		data = self:parse_dictionary_node(dict_node),
	}

	return http
end

---Parses a graphql vars block
---@return string|nil: the parsed graphql vars block
function Parser:parse_gql_vars_block()
	local query = vim.treesitter.query.parse(lang, "(bodies (body_graphql_vars) @block)")
	local body_block = self:find_first(query)
	if body_block == nil then
		return nil
	end

	local content_node = body_block:named_child(1)
	if content_node == nil then
		return nil
	end

	return self:parse_text_block_node(content_node)
end

---@class BruRequestBody
---@field type string: the content type of the body
---@field data string|table: the data of the body
BruRequestBody = {}

---Parses a body block
---@return BruRequestBody|nil: the parsed body block
function Parser:parse_body_block()
	local query = vim.treesitter.query.parse(lang, "(bodies (_) @block)")
	local body_block = self:find_first(query)
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
		type = self:get_node_text(keyword_node),
		data = {},
	}

	if body.type:find("form") then
		body.data = self:parse_dictionary_node(content_node)
	else
		body.data = self:parse_text_block_node(content_node)
	end

	if body.type == "body:graphql" then
		local vars = self:parse_gql_vars_block()
		if vars then
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
function Parser:parse_auth_block()
	local query = vim.treesitter.query.parse(lang, "(auths (_) @block)")
	local auth_block = self:find_first(query)
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
		type = self:get_node_text(keyword_node),
		data = self:parse_dictionary_node(dict_node),
	}
end

---@alias BruRequestHeaders table
BruRequestHeaders = {}

---Parses a headers block
---@return BruRequestHeaders|nil: the parsed headers block
function Parser:parse_headers_block()
	local query = vim.treesitter.query.parse(lang, "(headers) @block")
	local headers_node = self:find_first(query)
	if headers_node == nil then
		return nil
	end

	local dict_node = headers_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return self:parse_dictionary_node(dict_node)
end

---@alias BruRequestQuery table
BruRequestQuery = {}

---Parses a query block
---@return BruRequestQuery|nil: the parsed query block
function Parser:parse_query_block()
	local query = vim.treesitter.query.parse(lang, "(query) @block")
	local query_node = self:find_first(query)
	if query_node == nil then
		return nil
	end

	local dict_node = query_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return self:parse_dictionary_node(dict_node)
end

---@alias BruRequestPathParams table
BruRequestPathParams = {}

---Parses a path params block
---@return BruRequestPathParams|nil: the parsed path params block
function Parser:parse_path_params_block()
	local query = vim.treesitter.query.parse(lang, "(params (params_path) @block)")
	local query_node = self:find_first(query)
	if query_node == nil then
		return nil
	end

	local dict_node = query_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return self:parse_dictionary_node(dict_node)
end

---@alias BruRequestQueryParams table
BruRequestQueryParams = {}

---Parses a query params block
---@return BruRequestQueryParams|nil: the parsed query params block
function Parser:parse_query_params_block()
	local query = vim.treesitter.query.parse(lang, "(params (params_query) @block)")
	local query_node = self:find_first(query)
	if query_node == nil then
		return nil
	end

	local dict_node = query_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return self:parse_dictionary_node(dict_node)
end

---@alias BruEnvVars table
BruEnvVars = {}

---Parses a vars block
---@return BruEnvVars|nil: the parsed vars block
function Parser:parse_vars()
	local query = vim.treesitter.query.parse(lang, "(env_vars) @block")
	local env_vars_node = self:find_first(query)
	if env_vars_node == nil then
		return nil
	end

	local dict_node = env_vars_node:named_child(1)
	if dict_node == nil then
		return nil
	end

	return self:parse_dictionary_node(dict_node)
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
---@param content string: the content to parse
---@return BruRequest: the parsed request
function M.parse_request(content)
	local parser = Parser:new(content)

	local meta = parser:parse_meta_block()
	if meta == nil then
		error("No meta block found")
	end

	local http = parser:parse_http_block()
	if http == nil then
		error("No http block found")
	end

	---@type BruRequest
	local request = {
		meta = meta,
		http = http,
		body = parser:parse_body_block(),
		headers = parser:parse_headers_block(),
		query = parser:parse_query_block(),
		auth = parser:parse_auth_block(),
	}

	local path_params = parser:parse_path_params_block()
	if path_params then
		for k, v in pairs(path_params) do
			request.http.data.url = request.http.data.url:gsub(":" .. k, v)
		end
	end

	local query_params = parser:parse_query_params_block()
	if query_params then
		for k, v in pairs(query_params) do
			if request.query[k] then
				request.query[k] = request.query[k]:gsub(":" .. k, v)
			end
		end
	end

	return request
end

---An environment
---@class BruEnv
---@field vars BruEnvVars|nil:
BruEnv = {}

---Parses an environment
---@param content string: the content to parse
---@return BruEnv: the parsed environment
function M.parse_env(content)
	local parser = Parser:new(content)

	---@type BruEnv
	local env = {
		vars = parser:parse_vars(),
	}

	return env
end

return M
