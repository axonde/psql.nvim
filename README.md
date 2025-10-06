# psql.nvim

A lightweight Neovim plugin to work with PostgreSQL directly from your editor. Forget external connection managers—keep your workflow entirely within Neovim.

## ✨ Features

- **No External Dependencies**: Manages connections internally. The only requirement is having the `psql` command-line tool installed.
- **Simple Configuration**: Configure all your connections with a simple Lua table.
- **Interactive Shell**: Quickly launch a `psql` shell for any configured database in a Neovim terminal.
- **Run Queries**: Execute SQL from your buffer and see the results in a new split.

## ⚡️ Requirements

- Neovim >= 0.8
- `psql` command-line utility available in your system's `PATH`.

## 📦 Installation

Install using your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- lua/plugins/psql.lua
return {
  'axonde/psql.nvim',
  cmd = { 'Psql', 'PsqlExec', 'PsqlListDBs' },
  config = function()
    require('psql').setup({
      -- Your configuration here
    })
  end,
}
```

But this is not a perfect way, if you are sharing the config to a git instance, where people can get easily your credit information. To fix this (cause I have this problem, uuff it was an open source database credit) you can create a global `psql.json` file and store all the info in it.
And than create a config like this:

```lua
local function loadJsonFromFile(filepath)
	local file = io.open(filepath, "r")
	if not file then
		vim.notify("Cannot open the file: " .. filepath, vim.log.levels.ERROR)
		return nil
	end

	local content = file:read("*a")
	io.close(file)

	local ok, decoded_json = pcall(vim.fn.json_decode, content)

	if not ok then
		vim.notify("Ill formated JSON: " .. filepath, vim.log.levels.ERROR)
		return nil
	end

	return decoded_json
end

local connections = loadJsonFromFile("your-path-to-the-secret-file.json")

return {
	"axonde/psql.nvim",
	cmd = { "Psql", "PsqlExec", "PsqlListDBs" },
	config = function()
		require("psql").setup({
			connections = connections,
			runner_output = "split",
		})
	end,
}
```

## ⚙️ Configuration

Here is a full example of the `setup` function.

```lua
-- In your config function:
require('psql').setup({
  -- A list of your database connections
  connections = {
    {
      name = "My Local DB",
      -- You can use a standard PostgreSQL URL
      url = "postgresql://user:password@localhost:5432/mydatabase",
    },
    {
      name = "Work Staging (no password)",
      -- Or define connection parameters individually
      host = "staging.example.com",
      port = 5432,
      user = "readonly_user",
      dbname = "staging_db",
    },
  },

  -- Determines how query results are displayed.
  -- Can be 'split', 'vsplit', or 'term'.
  runner_output = 'split',
})
```

### Options

- `connections` (table): A list of your database connections. Each connection is a table that must have a `name` and either:
  - A `url` string.
  - Individual properties: `host`, `port`, `user`, `password`, `dbname`.
- `runner_output` (string): Defines where the output of non-interactive queries is shown.
  - `'split'`: In a new horizontal split (default).
  - `'vsplit'`: In a new vertical split.
  - `'term'`: In a new terminal buffer.

## 🚀 Usage

The plugin provides three main commands:

- `:Psql`
  Opens a selector (`vim.ui.select`) to choose a configured database. It then opens an interactive `psql` shell for that connection in a new terminal window.

- `:PsqlExec`
  Executes the entire content of the current buffer as a SQL query. It will first ask you to select a connection. The results are displayed based on your `runner_output` setting.

- `:PsqlListDBs`
  A shortcut to list all databases on a selected server (runs the `\l` command in `psql`).

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the [issues page](https://github.com/your-github-username/psql.nvim/issues).

## 📝 License

This project is licensed under the MIT License.
