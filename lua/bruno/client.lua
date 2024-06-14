local curl = require("plenary.curl")

local utils = require("bruno.utils")

local M = {}

---Sends a request
---@param request BruRequest: the request to send
---@param environment table: the environment to use
---@return table: the response
function M.bru_request(request, environment)
	print("bru request")
	utils.P({ request = request, environment = environment })

	local opts = {
		url = request.http.data.url,
		method = request.http.method,
		headers = request.headers or {},
		body = request.body.data,
		query = request.query,
	}

	--parse body and configure content-type header
	if request.body.type == "body:json" then
		opts.headers["content-type"] = "application/json"
	elseif request.body.type == "body:text" then
		opts.headers["content-type"] = "text/plain"
	elseif request.body.type == "body:xml" then
		opts.headers["content-type"] = "application/xml"
	elseif request.body.type == "body:graphql" then
		opts.headers["content-type"] = "application/json"
	elseif request.body.type == "body:sparql" then
		opts.headers["content-type"] = "application/sparql-results+json"
	elseif request.body.type == "body:form-urlencoded" then
		opts.headers["content-type"] = "application/x-www-form-urlencoded"
	elseif request.body.type == "body:multipart-form" then
		opts.headers["content-type"] = "multipart/form-data"
	end

	-- curl options
	-- auth = "Basic request auth, 'user:pass', or {"user", "pass"}" (string/array)

	--TODO: parse auth and configure headers
	--TODO: parse body and configure form

	print("curl options")
	utils.P(opts)

	local res = curl.request(opts)

	print("response")
	utils.P(res)

	return res
end

return M
