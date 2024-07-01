local M = {}

---Displays the result in headless mode
---@param result CurlResponse: the result to draw
function M.display_result(result)
	print("HTTP " .. result.status)

	for _, v in ipairs(result.headers) do
		print(v)
	end

	print()
	print(result.body)
end

---Displays the curl command in headless mode
---@param cmd string: the command to draw
function M.display_cmd(cmd)
	print(cmd)
end

return M
