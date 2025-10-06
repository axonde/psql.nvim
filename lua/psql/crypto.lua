--[[
  psql.nvim - Basic Crypto for Password Obfuscation
  This version uses a standard, correct, pure-Lua Base64 implementation.
]]

local config = require("psql.config")

local M = {}

-- =============================================================================
-- Каноническая и корректная реализация Base64 на чистом Lua
-- =============================================================================
do
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

	local function enc(data)
		return (
			(data:gsub(".", function(x)
				local r, b = "", x:byte()
				for i = 8, 1, -1 do
					r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
				end
				return r
			end) .. "0000"):gsub("%d%d%d%d%d%d", function(x)
				if #x < 6 then
					return ""
				end
				local c = 0
				for i = 1, 6 do
					c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
				end
				return b:sub(c + 1, c + 1)
			end) .. ({ "", "==", "=" })[#data % 3 + 1]
		)
	end

	local function dec(data)
		data = string.gsub(data, "[^" .. b .. "=]", "")
		return (
			data:gsub(".", function(x)
				if x == "=" then
					return ""
				end
				local r, f = "", b:find(x) - 1
				for i = 6, 1, -1 do
					r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
				end
				return r
			end):gsub("%d%d%d%d%d%d%d%d", function(x)
				if #x ~= 8 then
					return ""
				end
				local c = 0
				for i = 1, 8 do
					c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
				end
				return string.char(c)
			end)
		)
	end

	M.base64_encode = enc
	M.base64_decode = dec
end
-- =============================================================================

--- A simple XOR-based text transformation function.
--- @param text string The input text (plaintext or encrypted).
--- @return string The transformed text.
local function transform(text)
	local key = config.options.crypto_key
	if not key or #key == 0 then
		vim.notify("PSQL Crypto: `crypto_key` is not set!", vim.log.levels.WARN)
		return text
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
	return M.base64_encode(encrypted)
end

--- Decrypts text.
--- @param base64_text string Base64-encoded text to decrypt.
--- @return string The decrypted plaintext.
function M.decrypt(base64_text)
	local encrypted = M.base64_decode(base64_text)
	return transform(encrypted)
end

return M
