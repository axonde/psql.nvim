# psql.nvim

PostgreSQL plugin for Neovim.

## Installation

To install this with lazy nvim, just add the following to your config:

```lua
require('lazy').setup({
  {
    "axonde/psql.nvim"
  }
})
```

## Usage

Use [psqlcm](github.com/trstringer/psqlcm) to connect to your postgres database. Then run the following commands:

- `:PgRun` (`<leader>p`)
- `:PgCancel`
- `:PgTemp` to get a temporary SQL workspace
- `:PgGetTable`
- `:PgGetFunction`
- `:PgGetDatabase`

Important!
If you want to sync the connection with psqlcm (and you'll want it, because without it it will never work, you must (!) set the connection name with a comment.

For example, you have set a connection with [psqlcm](github.com/trstringer/psqlcm) like `connection-for-nvim`. So you must to create a single comment on top of your scratch:

```
-- psql:pg1758281367645
```

It's terrible important that you left this comment on the top of your file!

## Recommended keymaps

```lua
vim.keymap.set(
	'n',
	'<leader>x',
	psql.psql_run_curr_buf,
	{ desc = 'Execute the current buffer with psql' }
)

vim.keymap.set(
	'x',
	'<leader>p',
	'<ESC><CMD>lua require("psql").psql_run_visual()<CR>',
	{ desc = 'Execute selection with psql' }
)
```
