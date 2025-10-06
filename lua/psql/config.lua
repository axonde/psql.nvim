--[[
  psql.nvim - Configuration Management
  Holds default settings and merges them with user-provided config.
  This is the single source of truth for configuration.
]]

local M = {}

-- Default configuration values
M.options = {
	connections = {},
	crypto_key = "psql.nvim-is-awesome!",
	runner_output = "term",
}

--- Merges user configuration with the default one.
--- @param user_config table
function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.options, user_config or {})
end

return M
