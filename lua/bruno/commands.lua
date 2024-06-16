local M = {}

local parser = require("bruno.parser")
local client = require("bruno.client")

---Find the collection root for the given request path
---@param request_path string The path of the bru request file
---@return string|nil The path of the collection root
local function find_collection_root(request_path)
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

---Get the path of the environments directory for the given collection root
---@param collection_root string The path of the collection root
---@return string The path of the environments directory
local function get_environments_root(collection_root)
	return collection_root .. "/environments"
end

---Get the list of environment files in the given directory
---@param env_dir string The path of the environments directory
---@return table The list of environment files
local function get_environments(env_dir)
	return vim.fn.glob(env_dir .. "/*.bru", false, true)
end

---Prompt the user to select an environment file
---@param prompt string The prompt to display
---@param envs table The list of environment files
---@return string|nil The selected environment file
local function inputenvlist(prompt, envs)
	local inputs = { prompt }
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
---@param path string The path of the file
---@return string The content of the file
local function get_file_content(path)
	local f = io.open(path, "r")
	if f == nil then
		error("Could not open file: " .. path)
	end

	local content = f:read("*a")
	f:close()
	return content
end

--TODO: use args for variable overrides (baseUrl="https://example.com")
local function request()
	local request_file = vim.api.nvim_buf_get_name(0)
	local request_content = get_file_content(request_file)

	local req = parser.parse_request(request_content)
	local env = {
		vars = nil,
	}

	--find "bru.json" based on the request file path
	local collection_root = find_collection_root(request_file)

	if collection_root then
		local env_dir = get_environments_root(collection_root)
		local env_files = get_environments(env_dir)
		local has_ui = #vim.api.nvim_list_uis() ~= 0
		if #env_files ~= 0 and has_ui then
			local env_file = inputenvlist("Environment files:", env_files)
			if env_file then
				local env_content = get_file_content(env_file)
				env = parser.parse_env(env_content)
			end
		end
	end

	local res = client.bru_request(req, env)
	return res
end

function M.init(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "BrunoRun", request, { desc = "Run bruno request" })
end

return M
