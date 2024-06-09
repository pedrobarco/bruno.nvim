local curl = require("plenary.curl")

local utils = require("bruno.utils")

local M = {}

---An HTTP request
---@class Request
---@field url string: the url to send the request to
---@field method string: the method to use
---@field headers table?: the headers to send
---@field body string?: the body to send
---@field query table?: the query to send
---@field form table?: the form to send
---@field auth table?: the auth to use
Request = {}

-- auth         = "Basic request auth, 'user:pass', or {"user", "pass"}" (string/array)

---Sends a request
---@param request Request: the request to send
---@return table: the response
function M.request(request)
	utils.P(request)
	return curl.request(request)
end

return M
