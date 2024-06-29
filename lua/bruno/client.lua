local curl = require("plenary.curl")

local M = {}

---@class CurlOpts
---@field url string
---@field method string
---@field headers table
---@field body string|nil
---@field query table
CurlOpts = {}

---@class CurlResponse
---@field status number
---@field body string
---@field headers table
CurlResponse = {}

---Substitute a variable in a target
---@param var table: the variable to substitute
---@param target string: the target to substitute the variable in
---@return string: the target with the variable substituted
local function substitute_var(var, target)
	local new_target = target:gsub("{{" .. var.name .. "}}", var.value)
	return new_target
end

---Substitute all values in a table
---@param var table: the variable to substitute
---@param target table: the target to substitute the variable in
---@return table: the target with the variable substituted
local function substitute_table(var, target)
	local new_target = {}
	for k, v in pairs(target) do
		new_target[k] = substitute_var(var, v)
	end
	return new_target
end

---Builds the options for a curl request
---@param request BruRequest: the request to build the options for
---@param environment BruEnv: the environment to use
---@return CurlOpts: the options for the curl request
local function build_curl_opts(request, environment)
	-- print("bru request")
	-- utils.P({ request = request, environment = environment })

	---@type CurlOpts
	local opts = {
		url = request.http.data.url,
		method = request.http.method,
		headers = request.headers or {},
		query = request.query or {},
	}

	if request.body then
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

		-- hardcoded for now
		if type(request.body.data) == "string" then
			opts.body = tostring(request.body.data)
		end
	end

	-- parse env and substitute variables
	if environment.vars then
		for k, v in pairs(environment.vars) do
			local var = { name = k, value = v }
			opts.url = substitute_var(var, opts.url)
			opts.headers = substitute_table(var, opts.headers)
			opts.query = substitute_table(var, opts.query)

			if opts.body then
				opts.body = substitute_var(var, opts.body)
			end
		end
	end

	-- curl options
	-- auth = "Basic request auth, 'user:pass', or {"user", "pass"}" (string/array)

	--TODO: parse auth and configure headers
	--TODO: parse body and configure form

	return opts
end

---Sends a request
---@param request BruRequest: the request to send
---@param environment BruEnv: the environment to use
---@return CurlResponse: the response
function M.bru_request(request, environment)
	local opts = build_curl_opts(request, environment)
	local res = curl.request(opts)
	---@type CurlResponse
	return res
end

---Shares a curl request
---@param request BruRequest: the request to share
---@param environment BruEnv: the environment to use
---@return string: the command to run the request via curl
function M.bru_share(request, environment)
	local opts = build_curl_opts(request, environment)
	local cmd = "curl -X " .. opts.method:upper()
	local url = opts.url

	-- parse query
	if #opts.query > 0 then
		url = url .. "?"
		for k, v in pairs(opts.query) do
			url = url .. k .. "=" .. v
			if next(opts.query, k) then
				url = url .. "&"
			end
		end
	end
	cmd = cmd .. " '" .. url .. "'"

	-- parse headers
	for k, v in pairs(opts.headers) do
		cmd = cmd .. " -H '" .. k .. ": " .. v .. "'"
	end

	-- parse body
	if opts.body then
		cmd = cmd .. " -d '" .. opts.body .. "'"
	end

	return cmd
end

return M
