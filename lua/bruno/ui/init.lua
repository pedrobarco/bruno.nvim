local M = {}

local window = require("bruno.ui.window")
local headless = require("bruno.ui.headless")
local utils = require("bruno.utils")

function M.display_result(result)
	if utils.has_ui() then
		window.display_result(result)
	else
		headless.draw(result)
	end
end

function M.display_cmd(cmd)
	if utils.has_ui() then
		window.display_cmd(cmd)
	else
		headless.display_cmd(cmd)
	end
end

return M
