" psql.nvim - Plugin to work with PostgreSQL directly from Neovim
" Maintainer: psql.nvim developers
" Version: 1.0

if exists('g:loaded_psql_nvim')
  finish
endif
let g:loaded_psql_nvim = 1

" Command to set up the plugin with optional configuration
command! -nargs=? PSQLSetup lua require('psql').setup(<f-args>)

" Create SQL highlighting enhancements
augroup psql_nvim
  autocmd!
  autocmd FileType sql syntax keyword sqlKeyword SELECT INSERT UPDATE DELETE FROM WHERE
  autocmd FileType sql syntax keyword sqlKeyword GROUP BY HAVING ORDER ASC DESC LIMIT OFFSET
  autocmd FileType sql syntax keyword sqlKeyword JOIN INNER LEFT RIGHT OUTER FULL ON USING
  autocmd FileType sql syntax keyword sqlKeyword UNION ALL INTERSECT EXCEPT
  autocmd FileType sql syntax keyword sqlKeyword CREATE DROP ALTER TABLE INDEX SEQUENCE VIEW
  autocmd FileType sql syntax keyword sqlKeyword FUNCTION TRIGGER PROCEDURE
  autocmd FileType sql syntax keyword sqlType INT INTEGER SMALLINT BIGINT DECIMAL NUMERIC
  autocmd FileType sql syntax keyword sqlType REAL FLOAT DOUBLE PRECISION
  autocmd FileType sql syntax keyword sqlType CHAR CHARACTER VARCHAR TEXT
  autocmd FileType sql syntax keyword sqlType TIMESTAMP DATE TIME INTERVAL
  autocmd FileType sql syntax keyword sqlType BOOLEAN
  autocmd FileType sql syntax keyword sqlStatement COMMIT ROLLBACK BEGIN TRANSACTION SAVEPOINT
  autocmd FileType sql syntax keyword sqlConditional CASE WHEN THEN ELSE END
augroup END
