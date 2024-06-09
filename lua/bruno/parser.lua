local M = {}

local utils = require("bruno.utils")

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
		local key = pair:named_child(0)
		local value = pair:named_child(1)
		if key ~= nil and value ~= nil then
			dict[get_node_text(key)] = get_node_text(value)
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

---Parses an http block
---@return table|nil: the parsed http block
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

	local dict = parse_dictionary_node(dict_node)
	dict.method = get_node_text(method_node)

	return dict
end

---Parses a body block
---@return string|table|nil: the parsed body block
function M.parse_body_block()
	local query = vim.treesitter.query.parse("bru", "(bodies (_) @block)")
	local body_block = find_first(query)
	if body_block == nil then
		return nil
	end

	local content_node = body_block:named_child(1)
	if content_node == nil then
		return nil
	end

	if string.find(body_block:type(), "form") then
		return parse_dictionary_node(content_node)
	end

	return parse_text_block_node(content_node)
end

---An HTTP request
---@class BruRequest
---@field http table: the http block
---@field body string|nil: the body block
---@field form table|nil: the body form block
BrunoRequest = {}

---Parses a request
---@return BruRequest: the parsed request
function M.parse_request()
	local request = {}

	local http = M.parse_http_block()
	if http == nil then
		error("No http block found")
	end

	request.http = http

	local body = M.parse_body_block()
	if type(body) == "table" then
		request.form = body
	elseif type(body) == "string" then
		request.body = body
	end

	return request
end

return M
