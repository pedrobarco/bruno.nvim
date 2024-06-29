local M = {}

local window = require("bruno.ui.window")
local headless = require("bruno.ui.headless")
local utils = require("bruno.utils")

---Display the result
---@param result CurlResponse: the result to display
function M.display_result(result)
	if utils.has_ui() then
		window.display_result(result)
	else
		headless.display_result(result)
	end
end

---Display the command
---@param cmd string: the command to display
function M.display_cmd(cmd)
	if utils.has_ui() then
		window.display_cmd(cmd)
	else
		headless.display_cmd(cmd)
	end
end

return M
