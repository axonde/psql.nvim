--[[
  psql.nvim - Configuration Management
  Holds default settings and merges them with user-provided config.
]]

local M = {}

-- Default configuration values
M.config = {
	-- A list of database connections.
	-- Users will define this in their setup().
	-- Example:
	-- {
	--   name = "My Local DB",
	--   url = "postgresql://user:password@localhost:5432/mydatabase",
	-- }
	-- or
	-- {
	--   name = "My Other DB",
	--   host = "localhost",
	--   port = 5432,
	--   user = "user",
	--   password = "password",
	--   dbname = "other_db",
	-- }
	connections = {},

	-- A secret key for encrypting/decrypting passwords.
	-- WARNING: This provides basic obfuscation, not strong security.
	-- For better security, consider fetching passwords from a secure vault.
	-- It's highly recommended that the user overrides this with their own unique key.
	crypto_key = "psql.nvim-is-awesome!",

	-- How to open the psql shell or display query results.
	-- 'term': opens a new terminal window inside Neovim.
	-- 'split': opens a new split with the results.
	-- 'vsplit': opens a new vertical split with the results.
	runner_output = "term",
}

--- Merges user configuration with the default one.
--- @param user_config table
function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
