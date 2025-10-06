local M = {
	-- Default configuration
	values = {
		-- Data storage location (default: stdpath data/psql_nvim)
		storage_path = vim.fn.stdpath("data") .. "/psql_nvim",

		-- Default PostgreSQL connection parameters
		default_port = 5432,
		default_user = vim.env.USER or "postgres",

		-- Security settings
		encryption_key_command = nil, -- Command to retrieve encryption key
		store_password = false, -- Whether to store passwords

		-- UI settings
		show_result_in = "split", -- split, vsplit, tab, float
		float_border = "rounded", -- Border style for floating windows

		-- Buffer settings
		buffer_keywords = true, -- Enable SQL keywords in buffer

		-- Keymap settings
		keymaps = {
			execute_query = "<leader>pe",
			execute_file = "<leader>pf",
			list_connections = "<leader>pl",
			add_connection = "<leader>pa",
			edit_connection = "<leader>pe",
			remove_connection = "<leader>pr",
		},

		-- Connections (if user wants to define in config)
		connections = {},
	},
}

-- Setup function to merge user config with defaults
function M.setup(opts)
	opts = opts or {}

	-- Create recursive merge function
	local function merge(target, source)
		for k, v in pairs(source) do
			if type(v) == "table" and type(target[k]) == "table" then
				merge(target[k], v)
			else
				target[k] = v
			end
		end
		return target
	end

	-- Merge configs
	M.values = merge(M.values, opts)

	-- Ensure storage directory exists
	vim.fn.mkdir(M.values.storage_path, "p")

	return M.values
end

-- Get a config value
function M.get(key)
	if key == nil then
		return M.values
	end

	local keys = vim.split(key, ".", { plain = true })
	local value = M.values

	for _, k in ipairs(keys) do
		value = value[k]
		if value == nil then
			return nil
		end
	end

	return value
end

return M
