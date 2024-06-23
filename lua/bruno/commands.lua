local M = {}

local parser = require("bruno.parser")
local client = require("bruno.client")
local ui = require("bruno.ui")
local utils = require("bruno.utils")

---Find the collection root for the given request path
---@param request_path string: the path of the bru request file
---@return string|nil: the path of the collection root
local function find_collection_root(request_path)
	--find "bru.json" based on the request file path
	--start from the request path and go up until you find the collection root
	local path = request_path
	while true do
		local parent = vim.fn.fnamemodify(path, ":h")
		if parent == path then
			return nil
		end
		if vim.fn.filereadable(parent .. "/bruno.json") == 1 then
			return parent
		end
		path = parent
	end
end

---Prompt the user to select an environment file
---@param collection_root string: the path of the collection root
---@return string|nil: the selected environment file
local function select_env(collection_root)
	local env_dir = collection_root .. "/environments"
	local envs = vim.fn.glob(env_dir .. "/*.bru", false, true)
	local inputs = { "Environment files:" }
	for i, choice in ipairs(envs) do
		-- get the name of the file and remove the path
		choice = vim.fn.fnamemodify(choice, ":t:r")
		table.insert(inputs, i .. ": " .. choice)
	end
	local choice = vim.fn.inputlist(inputs)
	if choice == 0 then
		return nil
	end
	return envs[choice]
end

---Get the content of a file
---@param path string: the path of the file
---@return string: the content of the file
local function get_file_content(path)
	local f = io.open(path, "r")
	if f == nil then
		error("Could not open file: " .. path)
	end
	local content = f:read("*a")
	f:close()
	return content
end

---Build the request from the given file
---@param request_file string: the path of the request file
---@return BruRequest: the request
local function build_request(request_file)
	local request_content = get_file_content(request_file)
	local req = parser.parse_request(request_content)
	return req
end

---Build the environment from the given file
---@param request_file string: the path of the request file
---@param override_vars string: the variables to override (e.g. "baseUrl=https://example.com")
---@return BruEnv: the environment
local function build_environment(request_file, override_vars)
	local env = {
		vars = {},
	}

	local collection_root = find_collection_root(request_file)
	if collection_root then
		if utils.has_ui() then
			local env_file = select_env(collection_root)
			if env_file then
				local env_content = get_file_content(env_file)
				env = parser.parse_env(env_content)
			end
		end
	end

	local vars = vim.fn.split(override_vars, " ")
	for _, arg in ipairs(vars) do
		local parts = vim.fn.split(arg, "=")
		if #parts == 2 then
			env.vars[parts[1]] = parts[2]
		end
	end

	return env
end

---Run the bruno request
---@param opts table: the options for the request
---@return table: the response of the request
local function request(opts)
	local request_file = vim.api.nvim_buf_get_name(0)
	local req = build_request(request_file)
	local env = build_environment(request_file, opts.args)
	local res = client.bru_request(req, env)
	ui.display_result(res)
	return res
end

---Share the bruno request via curl
---@param opts table: the options for the request
---@return string: the command to run the request via curl
local function share(opts)
	local request_file = vim.api.nvim_buf_get_name(0)
	local req = build_request(request_file)
	local env = build_environment(request_file, opts.args)
	local cmd = client.bru_share(req, env)
	ui.display_cmd(cmd)
	return cmd
end

---Initialize the commands for the given buffer
---@param bufnr number: the buffer number
function M.init(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoRun", request, {
		nargs = "*",
		desc = "Run bruno request",
	})
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoShare", share, {
		nargs = "*",
		desc = "Share bruno request",
	})
end

return M
