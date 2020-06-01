# tx.nvim

`tx` build vim command with `:terminal` outputs

## Install

### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'xztaityozx/tx.nvim'
```

## Usage
Call `tx#start({cmds}, {options})` or call `tx#call({name})` after `tx#register({name}, {cmds}, {options})`.

## Configuration

### `{cmds}`
`{cmds}` is list of commands. For example, if `{cmd}` is `[["ls","-1"], ["fzf"]]`, `tx` converts it to `ls -1 | fzf`.

#### `[[::tx_arg::]]`
If `[[::tx_arg::]]` appears in `{cmds}`, `tx` replaces it with the value entered from the Vim prompt(`input('tx >>> ')`).

### `{options}`
`{options}` is option for `tx`

|name|description|default|example|  
|:--:|:--:|:--:|:--:|  
|`shellOptions`|options for `$SHELL`|`[]`|`{'shellOptions': ["--pipefail"]}`|  
|`cursor`|||`{'cursor': 'lc'}` => invoke cursor(line, column) after command. `{'cursor': 'l'}` => invoke cursor(line, 1)|  
|`vimCmd`|vim command|`edit`|`{'vimCmd': 'terminal'}`|  

### Example
```vim
Plug 'xztaityozx/tx.nvim'
"{{{
  autocmd VimEnter * call s:tx_my_settings()
  function! s:tx_my_settings() abort
    call tx#register('rg', [
          \["rg","--vimgrep", "[[::tx_arg::]]"], 
          \["fzf","-m"],
          \["awk", "-F:", "-v OFS=:", "'{print $1,$2,$3}'"]
        \], {
          \'shellOptions':["--pipefail"],
          \'cursor': 'lc'
        \})
    call tx#register('git ls-files', [
      \["git", "ls-files"], ["fzf", "-m"]
      \], {'shellOptions': ["--pipefail"]})

    call tx#register('cd', [["fd", "--type=d"],["fzf"]], {'vimCmd':'cd'})
    
    nnoremap <silent> sk :<C-u>call tx#call('git ls-files')<CR>
    nnoremap <silent> sgg :<C-u>call tx#call('rg')<CR>
    nnoremap <silent> scd :<C-u>call tx#call('cd')<CR>

    tmap <silent><expr> <ESC> (&filetype == "Tx") ? "<Plug>(tx_cancel)": "<c-\><c-n>"
  endfunction
"}}}
```
