local M = {}

-- We'll use a simple encryption method for storing sensitive data
-- In a production plugin, you might want to use a more secure method
-- or integrate with an external password manager

local function get_encryption_key()
	local config = require("psql.config")

	-- Try to get encryption key from command if configured
	local key_command = config.get("encryption_key_command")
	if key_command then
		local handle = io.popen(key_command)
		if handle then
			local result = handle:read("*a")
			handle:close()
			return result:gsub("[\n\r]", "")
		end
	end

	-- Generate a stable key based on machine-specific info if no command provided
	local hostname = vim.loop.os_gethostname() or ""
	local username = vim.env.USER or vim.env.USERNAME or ""
	local homedir = vim.env.HOME or vim.env.USERPROFILE or ""

	return vim.fn.sha256(hostname .. username .. homedir)
end

-- Simple XOR encryption
function M.encrypt(text)
	if not text or text == "" then
		return ""
	end

	local key = get_encryption_key()
	local result = {}

	for i = 1, #text do
		local byte = text:byte(i)
		local key_byte = key:byte((i % #key) + 1)
		table.insert(result, string.char(bit.bxor(byte, key_byte)))
	end

	return vim.fn.base64encode(table.concat(result))
end

function M.decrypt(encrypted)
	if not encrypted or encrypted == "" then
		return ""
	end

	local decoded = vim.fn.base64decode(encrypted)
	if not decoded then
		return ""
	end

	local key = get_encryption_key()
	local result = {}

	for i = 1, #decoded do
		local byte = decoded:byte(i)
		local key_byte = key:byte((i % #key) + 1)
		table.insert(result, string.char(bit.bxor(byte, key_byte)))
	end

	return table.concat(result)
end

return M
