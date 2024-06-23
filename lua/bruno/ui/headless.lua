local M = {}

local utils = require("bruno.utils")

---Displays the result in headless mode
---@param result table: the result to draw
function M.display_result(result)
	utils.P(result)
end

---Displays the curl command in headless mode
---@param cmd string: the command to draw
function M.display_cmd(cmd)
	utils.P(cmd)
end

return M
