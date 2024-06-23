local M = {}

local buffer = require("bruno.ui.buffer")
local headless = require("bruno.ui.headless")
local utils = require("bruno.utils")

function M.display_result(result)
	if utils.has_ui() then
		buffer.display_result(result)
	else
		headless.draw(result)
	end
end

function M.display_cmd(cmd)
	if utils.has_ui() then
		buffer.display_cmd(cmd)
	else
		headless.display_cmd(cmd)
	end
end

return M
