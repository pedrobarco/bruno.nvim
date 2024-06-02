local M = {}

local commands = require("bruno.commands")

function M.setup()
	local rest_nvim_augroup = vim.api.nvim_create_augroup("Bruno", {})
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = rest_nvim_augroup,
		pattern = "*.bru",
		callback = function(args)
			commands.init(args.buf)
		end,
		desc = "Set up bruno.nvim commands",
	})
end

return M
