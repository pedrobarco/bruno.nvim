local curl = require("plenary.curl")

local utils = require("bruno.utils")

local M = {}

---Sends a request
---@param request BruRequest: the request to send
---@param environment table: the environment to use
---@return table: the response
function M.bru_request(request, environment)
	utils.P(request)
	utils.P(environment)

	local opts = {
		url = request.http.data.url,
		method = request.http.method,
		headers = request.headers,
		body = request.body.data,
		query = request.query,
	}

	-- curl options
	-- auth = "Basic request auth, 'user:pass', or {"user", "pass"}" (string/array)

	--TODO: parse auth and configure headers
	--TODO: parse body and configure form
	--TODO: parse body and configure content-type header

	return curl.request(opts)
end

return M
