local M = {}

local autocmds = require("bruno.autocmds")

function M.setup()
	-- check if treesitter for bruno is installed
	local status = pcall(require, "nvim-treesitter")
	if not status then
		error("nvim-treesitter is not installed")
	end

	-- check if the bruno parser is installed
	local parsers = require("nvim-treesitter.parsers")
	if not parsers.has_parser("bru") then
		error("bru parser is not installed")
	end

	-- setup autocmds and commands
	autocmds.setup()
end

return M
