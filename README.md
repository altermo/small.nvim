# Small.nvim
This is my personal collection of small plugins that I created for myself.

**As it is my personal plugins, I might change things without warning.**

I would recommend checking out [whint](##Whint), [bufend](##Bufend) and [dff](##Dff) as those are the ones that helps me the most.

Global optional but recommend dependencies:
+ `nvim-telescope/telescope-ui-select.nvim`: many plugins use `vim.ui.select`
+ `rcarriga/nvim-notify` many plugins use `vim.notify`

## Bufend
Required: [`fd`](https://github.com/sharkdp/fd) \
Bufend makes it easy to quickly goto a specific file in your file system.
<details><summary>Here is some pseudocode of what <code>bufend.run()</code> does</summary>

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
Optional: `python`,`mojo`,`fish`,`lua5.1`,`fennel`,`dotnet`,`rust`,`zig` (used also for c/c++),`make`\
Basically, a simple run file system.\
It currently has the following commands:
+ `builder.termbuild` runs the file in the terminal
+ <s>`builder.build` runs the file in the quickfix window</s>
+ `builder.eval` evaluates the file as vim code
+ `builder.swap` swap commonly used runners
+ `builder.set` set the builder for the current filetype\
It also has the following table as options:
+ `builder.builders` a table of builders

## Chat
Required: [`tgpt`](https://github.com/aandrew-me/tgpt)
Has one function `chat.run()`, which asks for input and gives the response in a buffer.

## Dff
The hop/leap/flash style selector + a file explorer (not manager).\
Currently, it has only one function to run, `dff.file_expl(dir?)`, which opens a dff selector.\
<details><summary>The dff selector uses the following algorithm</summary>

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

## Foldselect
Has one function `chat.run()`, which makes it possible to select and go to folds.

## Highlight_selected
Has `highlight_selected.setup()`. \
Highlight the selected text in visual mode.

## Labull
Has one function `labull.run()`, which is newline and auto adds bullets for bullet-list.

## Lbpr
Code based replace file wide.\
Has one function `lbpr.run()`, which opens the editor plane.\
`:w` on script buf to run script.\
`:w` on preview buf to save changes.\
Inspired by [pyro](https://github.com/rraks/pyro)

## Macro
A simple macro plugin \
Has the following functions:
+ `macro.toggle_rec()`: toggle the recoding of macro
+ `macro.play_rec()`: play the macro
+ `macro.edit_rec()`: edit the macro

## Matchall
Match current word + vim.lsp.buf.document_highlight

## Nodeswap
Required: `treesitter`
Smarter node swap \
Has the following functions:
+ `nodeswap.swap_next()` swap with next node
+ `nodeswap.swap_prev()` swap with prev node
+ `nodeswap.over()` undo swap and swap with parent node \
And the following table as options:
+ `nodeswap.nodes` which tsnodes should be considered as nodes

## Onelinecomment
Optional: `treesitter`
Has one function `onelinecomment.run()`, which comments out the text, supports both normal and visual mode, can detect filetype with treesitter.

## Own
Colorscheme

## Plugin_search
Required: `curl`
Has one function `plugin_search.run()`, which searches and download and inits plugins using [nvim.sh](https://nvim.sh/)

## Ranger
Required: `ranger`
Has one function `ranger.run(file?)`, which runs ranger

## Reminder
Has `reminder.setup()`. \
Requires `reminder.path` to be set.\
Searches the `reminder.path` for any bullet list using `-`, and a date `(@YYYY-MM-DD HH:MM)`, and does a reminder when the time comes.

## Splitbuf
A replacement for `:split` and `:vsplit`.\
Has the following functions:
+ `splitbuf.split()`: splits then `splitbuf.open()`
+ `splitbuf.vsplit()` splits then `splitbuf.open()`
+ `splitbuf.open()`:
    Opens a window with some commands, if you press a key linked with the command, the command will run, otherwise the key will be sent to the buffer\
And has the following table as options:
+ `splitbuf.options` a table of commands

## Tabline
Has `tabline.setup()`.\
A simple tabline.

## Textobj
Text-objs to get a row/column of the same character.
<details><summary>Recommended config</summary>

```lua
vim.keymap.set('x','im',textobj.wordcolumn,{expr=true})
vim.keymap.set('o','im',textobj.charcolumn,{expr=true})
vim.keymap.set('x','ik',textobj.wordrow,{expr=true})
vim.keymap.set('o','ik',textobj.charrow,{expr=true})
```
</details>

## Trans
Requires `translate-shell`\
Simple translation plugin.\
Has the following functions:
+ `trans.cword()` translate the current word\
And the following table as options:
+ `trans.from` the language to translate from
+ `trans.to` the language to translate to

## Unimpaired
Goto next/previous file\
Or quickly change options\
Has the following functions:
+ `unimpaired.edit_next_file()`: edit next file
+ `unimpaired.edit_prev_file()`: edit prev file
+ `set_opt`: set option

## Whint
Basically:
```lua
function fun(arg|) end
--> :
---@param arg |
function fun(arg) end
--> -
---@param arg
function fun(arg|) end
```
<details><summary>Recommended config</summary>

```lua
vim.keymap.set('i',':',whint.run_wrapp(':'),{expr=true})
```
</details>

## Zen
Simple zen\
Has one function `zen.run()`, which makes zen

## Donate
If you want to donate then you need to find the correct link (hint: chess-bird):
* [0a]() [0b]() [0c]() [0d]() [0e]() [0f]() [0g]() [0h]()
* [1a]() [1b]() [1c]() [1d]() [1e]() [1f]() [1g]() [1h]()
* [2a]() [2b]() [2c]() [2d]() [2e]() [2f]() [2g]() [2h]()
* [3a]() [3b]() [3c]() [3d]() [3e]() [3f]() [3g]() [3h]()
* [4a]() [4b]() [4c]() [4d]() [4e]() [4f](https://www.buymeacoffee.com/altermo) [4g]() [4h]()
* [5a]() [5b]() [5c]() [5d]() [5e]() [5f]() [5g]() [5h]()
* [6a]() [6b]() [6c]() [6d]() [6e]() [6f]() [6g]() [6h]()
