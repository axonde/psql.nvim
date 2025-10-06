--[[
  psql.nvim - Basic Crypto for Password Obfuscation
  WARNING: This is NOT a cryptographically secure implementation.
  It only serves to avoid storing passwords in plaintext.
]]

local config = require("psql.config")

local M = {}

--- A simple XOR-based text transformation function.
--- @param text string The input text (plaintext or encrypted).
--- @return string The transformed text.
local function transform(text)
	local key = config.config.crypto_key
	if not key or #key == 0 then
		vim.notify("PSQL Crypto: `crypto_key` is not set!", vim.log.levels.WARN)
		return text -- Return as-is if key is missing
	end

	local result = {}
	for i = 1, #text do
		local char_code = string.byte(text, i)
		local key_char_code = string.byte(key, (i - 1) % #key + 1)
		table.insert(result, string.char(bit.bxor(char_code, key_char_code)))
	end
	return table.concat(result)
end

--- Encrypts text using a simple XOR cipher.
--- @param plaintext string The text to encrypt.
--- @return string Base64-encoded encrypted text.
function M.encrypt(plaintext)
	local encrypted = transform(plaintext)
	return vim.fn.base64encode(encrypted)
end

--- Decrypts text.
--- @param base64_text string Base64-encoded text to decrypt.
--- @return string The decrypted plaintext.
function M.decrypt(base64_text)
	local encrypted = vim.fn.base64decode(base64_text)
	return transform(encrypted)
end

return M
