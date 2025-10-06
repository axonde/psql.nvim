--[[
  psql.nvim - Entry point
  Defines user-facing commands.
]]

-- Define the main command for the plugin
vim.api.nvim_create_user_command("Psql", function()
	require("psql.ui").select_and_connect()
end, {
	nargs = 0,
	desc = "PSQL: Open a connection selection window",
})

-- A command to run a query from the current buffer
vim.api.nvim_create_user_command("PsqlExec", function()
	require("psql.ui").execute_current_buffer()
end, {
	nargs = 0,
	desc = "PSQL: Execute the content of the current buffer on a selected connection",
})

-- A command to list databases
vim.api.nvim_create_user_command("PsqlListDBs", function()
	require("psql.ui").list_databases()
end, {
	nargs = 0,
	desc = "PSQL: List[48;45;144;1800;2880t databases on a selected connection",
})
