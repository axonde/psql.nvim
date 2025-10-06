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
