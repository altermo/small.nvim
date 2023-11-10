# Small.nvim
This is my personal collection of small plugins that I created for myself.

**As it is my personal plugins, I might change things without warning.**

The documentation might not be up to date

I would recommend checking out [whint](#Whint), [bufend](#Bufend) and [dff](#Dff) as those are the ones that helps me the most.

Optional dependencies:
+ `nvim-telescope/telescope-ui-select.nvim`: many plugins use `vim.ui.select`
+ `rcarriga/nvim-notify` many plugins use `vim.notify`

## Beacon
Summary: Simple flash cursor at pos. \
Commands:
+ `beacon.flash` flashes the cursor
+ `beacon.create_autocmd` returns an autocmd to flash the cursor on move

Config:
+ `beacon.conf.interval` ms between flashes
+ `beacon.conf.count` how many flashes
+ `beacon.conf.color` color of flash (may be #rgb or color-name)
+ `beacon.conf.minimal` minimal size of move to flash cursor

## Bufend
Summary: Bufend makes it easy to quickly goto a specific file in your file system. \
Commands: `bufend.run()`
<details><summary>Pseudocode explanation: of what <code>bufend.run()</code> does</summary>

```python
char=getchar()
if char=='<esc>':return
elif char=='<tab>':
    set_mark(getchar(),select_file_from_opend())
elif char=='<bs>':
    del_mark(getchar())
elif char=='<cr>':
    edit(select_file_from_opend())
else:
    if marks[char]:
        edit(marks[char])
    elif (files:=get_opened_file_with_starting_char(char)):
        edit(files[0] if len(files)==1 or select(files))
    else:
        edit(select(get_files_with_starting_char(char)))
```
</details>

## builder
Optional: `python`,`mojo`,`fish`,`lua5.1`,`fennel`,`dotnet`,`rust`,`zig` (used also for c/c++),`make` \
Summary: Basically, a simple run file system. \
Commands:
+ `builder.termbuild` runs the file in the terminal
+ `builder.eval` evaluates the file as vim code
+ `builder.swap` swap commonly used runners (like `rustc` and `cargo run`)
+ `builder.set` set the builder for the current filetype

Config:
+ `builder.conf.builders` a table of builders, (see source code)

## Chat
Required: [`tgpt`](https://github.com/aandrew-me/tgpt)\
Summary: Runs tgpt in buffer\
Commands: `tgpt.run()`

## Cmd2ins
Summary: Run insert mappings (like [nvim-autopairs](https://github.com/windwp/nvim-autopairs)) in the cmdline \
Commands:
+ `cmd2ins.map(key)` run key from command mode in insert mode

## Dff
Summary: The hop/leap/flash style selector + a file explorer (not manager).\
Commands:
+ `dff.file_expl(dir?)` opens a dff file selector. Use `<esc>` to quit.
<details><summary>Pseudocode explanation: of how the dff algorithm works</summary>

```python
items=get_items()
col=0
while len(items)!=1:
    char_at_col=items[0][col]
    while all(map(lambda x:x[col]==char_at_col,items)):
        col=col+1
    char=getchar()
    if char=='<esc>':break
    items=filter(lambda x:x[col]==char,items)
```
</details>
<!-- TODO: write about config-->

## Exchange
Summary: Exchange two selected regions. \
Commands:
+ `exchange.ex_line()` exchange current line
+ `exchange.ex_oper()` exchange operator
+ `exchange.ex_visual()` exchange visual
+ `exchange.ex_eol()` exchange to end of line
+ `exchange.ex_cancel()` cancel exchange

Keymap (example):
```lua
vim.keymap.set('n','cx',exchange.ex_oper)
vim.keymap.set('n','cX',exchange.ex_eol)
vim.keymap.set('n','cxx',exchange.ex_line)
vim.keymap.set('n','cxc',exchange.ex_cancel)
vim.keymap.set('x','X',exchange.ex_visual)
```

## Foldselect
Summary: Select from folds using `vim.ui.select`. \
Commands: `foldselect.run()`

## Foldtext
Summary: A simple foldtext. \
Setup: `foldtext.setup()`
Config:
+ `foldtext.conf.treesitter` whether to use treesitter Highlighting

## Help_readme
Required: `ctags`\
Summary: Generates tag with the prefix `readme-` from readme files (so that you can `:help readme-*`). \
Setup: `help_readme.setup()` \
Commands:
+ `help_readme.generate()` generate tag file from readme to path

Config:
+ `help_readme.conf.path` where the readmes/tagfile is put

## Highlight_selected
Summary: Highlight matching selected text in visual mode. \
Setup: `highlight_selected.setup()`

## Kitty
Summary: Synchronize with kitty terminal\
NOTE: Can't be configured yet.\
Setup: `kitty.setup()`

## Labull
Summary: Auto adds bullets for bullet-list.\
Commands: `labull.run()` (map-expr)
Keymap (example):
```lua
vim.keymap.set('n','o',labull.run,{expr=true})
```
## Lbpr
Inspired by: [pyro](https://github.com/rraks/pyro) \
Summary: Code based replace file wide. \
Commands: `lbpr.run()` \
NOTE:
+ `:write` on script buf to run script.
+ `:write` on preview buf to save changes.
## Macro
Summary: A simple macro plugin \
Commands:
+ `macro.toggle_rec()`: toggle the recoding of macro
+ `macro.play_rec()`: play the macro
+ `macro.edit_rec()`: edit the macro
## Matchall
Summary: Match current word + vim.lsp.buf.document_highlight\
Setup: `matchall.setup()`
## Nodeswap
Required: `treesitter`\
Summary: Smarter node swap \
Commands:
+ `nodeswap.swap_next()` swap with next node
+ `nodeswap.swap_prev()` swap with prev node
+ `nodeswap.over()` undo swap and swap with parent node

Config:
+ `nodeswap.conf.nodes` which tsnodes should be considered as nodes
## Nterm
Summary: Run terminal or use neovim as a terminal.\
Commands:
+ `nterm.run(cmd?,smart_quit_nvim?)` creates a new termial
    + `cmd?`: the cmd to run, defaults to `&shell`
    + `smart_quit_nvim?`: if is the only buffer open, quits neovim

Example:
Here is an example of how to use neovim-qt as a terminal:
```bash
nvim-qt -- -c "lua require'small.nterm'.run(nil,true)"
```
## Onelinecomment
Optional: `treesitter` \
Summary: Toggle comments out the text, can detect filetype with treesitter. \
Commands: `onelinecomment.run()` (map-expr) \
Keymap (example):
```lua
vim.keymap.set('x','gc',onelinecomment.run)
vim.keymap.set('n','gc',onelinecomment.run)
```
## Own
Summary: Colorscheme
## Plugin_search
Required: `curl` \
Summary: Searches and download and inits plugins using [nvim.sh](https://nvim.sh/) \
Commands: `plugin_search.run()`
## Ranger
Required: `ranger` \
Summary: simple `ranger` wrapper \
Commands: `ranger.run(file?)` \
Config:
+ `ranger.conf.exit_if_single`: exit neovim when quitting ranger if it is the only buffer
## Reminder
Summary: Searches the `reminder.conf.path` for any bullet list with `-`, and a date `(@YYYY-MM-DD HH:MM)`, and does a reminder when the time comes. \
Setup: `reminder.setup()`\
Config:
+ `reminder.conf.path` (required) file to find reminders in
## Splitbuf
Summary: A replacement for `:split` and `:vsplit`.\
Commands:
+ `splitbuf.split()`: splits then `splitbuf.open()`
+ `splitbuf.vsplit()` splits then `splitbuf.open()`
+ `splitbuf.open()`: Opens a window with some commands, if you press a key linked with the command, the command will run, otherwise the key will be sent to the buffer

Config:
+ `splitbuf.conf.options` a table of commands (see source code)
## Tabline
Summary: A simple tabline. \
Setup: `tabline.setup()`
## Textobj
Summary: Text-objs to get a row/column of the same character. \
Commands:
+ `textobj.wordcolumn` get same selected in column (map-expr)
+ `textobj.charcolumn` get same char in column (map-expr)
+ `textobj.wordrow` get same selected in row (map-expr)
+ `textobj.charrow` get same char in row (map-expr)
Keymap (example):
```lua
vim.keymap.set('x','im',textobj.wordcolumn,{expr=true})
vim.keymap.set('o','im',textobj.charcolumn,{expr=true})
vim.keymap.set('x','ik',textobj.wordrow,{expr=true})
vim.keymap.set('o','ik',textobj.charrow,{expr=true})
```
## Trans
Requires: `translate-shell`\
Summary: Simple translation plugin.\
Commands:
+ `trans.cword()` translate the current word

Config:
+ `trans.conf.from` the language to translate from (can be modified whenever)
+ `trans.conf.to` the language to translate to (can be modified whenever)
## Tree_lua_block_split_join
Required: `treesitter`\
Summary: Split-join if/for/function_definition blocks\
Commands: `tree_lua_block_split_join.run()`

## Unimpaired
Summary: Goto next/previous file OR quickly change options\
Commands:
+ `unimpaired.edit_next_file()`: edit next file
+ `unimpaired.edit_prev_file()`: edit prev file
+ `set_opt`: set option (and opens a preview window)
## Whint
Summary: Basically:
```lua
function fun(arg|) end
--> :
---@param arg |
function fun(arg) end
--> -
---@param arg
function fun(arg|) end
```
Commands: `whint.run()` (map-expr)\
Keymap (example):
```lua
vim.keymap.set('i',':',whint.run,{expr=true})
```
## Zen
Summary: Simple zen \
Commands: `zen.run()`

## Donate
If you want to donate then you need to find the correct link (hint: chess-bird):
* [0a]() [0b]() [0c]() [0d]() [0e]() [0f]() [0g]() [0h]()
* [1a]() [1b]() [1c]() [1d]() [1e]() [1f]() [1g]() [1h]()
* [2a]() [2b]() [2c]() [2d]() [2e]() [2f]() [2g]() [2h]()
* [3a]() [3b]() [3c]() [3d]() [3e]() [3f]() [3g]() [3h]()
* [4a]() [4b]() [4c]() [4d]() [4e]() [4f](https://www.buymeacoffee.com/altermo) [4g]() [4h]()
* [5a]() [5b]() [5c]() [5d]() [5e]() [5f]() [5g]() [5h]()
* [6a]() [6b]() [6c]() [6d]() [6e]() [6f]() [6g]() [6h]()
<!-- vim:ft=markdown: -->
