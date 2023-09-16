---@alias own.themes 'day'|'midnight'|'evening'|'transparent'|nil
---@class own.color table
---@field pallet own.pallet
---@field [string] any
---@class own.pallet
---@field mainbg string
---@field mainfg string
---@field secondbg string
---@field nimportant string
---@field selectbg string
---@field select2bg string
---@field visual string
---@field yellow string
---@field purple string
---@field pink string
---@field red string
---@field important string
---@field func string
---@field var string
---@field block string
---@field green string

local M={}
---@param theme own.themes
function M.setup(theme)
    if not theme then
        if vim.fn.filereadable('/tmp/night')==1 then
            theme='midnight'
        elseif vim.env.TRANSPARENT then
            theme='transparent'
        else
            if vim.o.background=='light' then
                theme='day'
            else
                theme='evening'
            end
        end
    end
    M.load(theme)
end
---@param theme own.themes
function M.load(theme)
    M.set_highlights(require('small.own.theme.'..theme))
end
---@param color own.color
function M.set_highlights(color)
    local p=color.pallet
    vim.cmd'highlight clear'
    local function set_hl(name,val)
        vim.api.nvim_set_hl(0,name,val)
    end
    local linebg=p.secondbg
    local secondfg=p.nimportant
    local err=p.red
    local warning=p.yellow
    local selectfg=p.important
    local u='#ff0000'
    local m=p.mainbg
    local invred=m~='' and '#'..(tonumber(m:sub(2,2))+2)..m:sub(3) or '#400000'
    local invgreen=m~='' and '#'..m:sub(2,3)..(tonumber(m:sub(4,4))+2)..m:sub(5) or '#004000'
    local invyellow=m~='' and '#'..(tonumber(m:sub(2,2))+2)..m:sub(3,3)..(tonumber(m:sub(4,4))+2)..m:sub(5) or '#000040'
    ---NORMAL
    set_hl('Normal',{bg=p.mainbg,fg=p.mainfg})
    set_hl('NormalFloat',{bg=p.secondbg~='' and p.secondbg or p.select2bg,fg=p.mainfg})
    set_hl('EndOfBuffer',{})
    ---VISUAL
    set_hl('Visual',{bg=p.visual})
    ---CURSOR/COLUM
    set_hl('LineNr',{bg=linebg,fg=secondfg})
    set_hl('CursorLineNr',{bg=linebg,fg=p.yellow})
    set_hl('Cursor',{bg=p.mainfg})
    set_hl('CursorLine',{bg=p.secondbg})
    set_hl('CursorColumn',{bg=linebg})
    ---FOLD/COLUMNS
    set_hl('Folded',{bg=linebg,fg=p.mainfg})
    set_hl('FoldColumn',{bg=linebg,fg=p.purple})
    set_hl('SignColumn',{bg=linebg})
    set_hl('ColorColumn',{bg=linebg})
    ---TERM
    set_hl('TermCursor',{link='Cursor'})
    set_hl('TermCursorNC',{link='TermCursor'})
    ---MENU|SPLIT
    set_hl('WildMenu',{bg=u})
    set_hl('WinSeparator',{bg=p.mainbg})
    ---TAB
    set_hl('TabLine',{bg=p.secondbg,fg=secondfg})
    set_hl('TabLineSel',{bg=p.selectbg,fg=selectfg,bold=true})
    set_hl('TabLineFill',{bg=p.secondbg})
    ---STATUS
    set_hl('StatusLine',{bg=p.secondbg,fg=p.mainfg})
    set_hl('StatusLineNC',{bg=p.secondbg,fg=secondfg})
    ---PMENU
    set_hl('Pmenu',{bg=p.secondbg~='' and p.secondbg or p.select2bg,fg=p.mainfg})
    set_hl('PmenuSel',{bg=p.selectbg,fg=selectfg,bold=true})
    set_hl('PmenuSbar',{bg=p.secondbg~='' and p.secondbg or p.select2bg,fg=p.mainfg})
    set_hl('PmenuThumb',{bg=p.selectbg})
    ---SEARCH
    set_hl('Search',{bg=p.selectbg})
    set_hl('IncSearch',{link='Search'})
    set_hl('CurSearch',{bg=p.select2bg})
    set_hl('Substitute',{link='CurSearch'})
    ---OTHER
    set_hl('Conceal',{fg=u})
    set_hl('SpecialKey',{fg=secondfg,bold=true})
    set_hl('NonText',{fg=secondfg})
    set_hl('MatchParen',{bg=p.select2bg})
    set_hl('Whitespace',{fg=secondfg})
    set_hl('Directory',{fg=p.pink})
    set_hl('Title',{fg=p.yellow,bold=true})
    set_hl('Todo',{fg=p.important})
    set_hl('Bold',{bold=true})
    set_hl('Italic',{italic=true})
    vim.cmd.highlight('Underline guibg=none guifg=none gui=underline')
    set_hl('Error',{bg=err})
    ---MSG_AREA
    set_hl('MoreMsg',{fg=selectfg,bold=true})
    set_hl('Question',{fg=selectfg,bold=true})
    ---MSG
    set_hl('WarningMsg',{fg=warning})
    set_hl('ErrorMsg',{fg=err})
    set_hl('ModeMsg',{fg=p.important})
    ---CHECKHEALT
    set_hl('healthError',{link='ErrorMsg'})
    set_hl('healthSuccess',{link='Msg'})
    set_hl('healthWarning',{link='WarningMsg'})
    ---MAIN
    set_hl('Tag',{fg=p.important})
    set_hl('Link',{bg=u})
    set_hl('URL',{bg=u})
    set_hl('Underlined',{fg=p.important})
    set_hl('Comment',{fg=p.nimportant})
    ---CAT1
    set_hl('Macro',{fg=p.purple})
    set_hl('Define',{fg=p.pink})
    set_hl('Include',{fg=p.pink})
    set_hl('PreProc',{fg=p.important})
    set_hl('PreCondit',{bg=u})
    ---CAT2
    set_hl('Label',{fg=p.important})
    set_hl('Repeat',{fg=p.block})
    set_hl('Keyword',{fg=p.yellow})
    set_hl('Operator',{fg=p.yellow})
    set_hl('Delimiter',{fg=p.yellow})
    set_hl('Statement',{fg=p.yellow})
    set_hl('Exception',{fg=p.block})
    set_hl('Conditional',{fg=p.block})
    ---CAT3
    set_hl('Variable',{fg=p.var})
    set_hl('VariableBuiltin',{bg=u})
    set_hl('Constant',{fg=p.important})
    ---CAT4
    set_hl('Number',{fg=p.purple})
    set_hl('Float',{fg=p.purple})
    set_hl('Boolean',{fg=p.pink})
    set_hl('Enum',{bg=u})
    ---CAT5
    set_hl('SpecialChar',{link='SpecialKey'})
    set_hl('String',{fg=p.green})
    set_hl('Character',{link='String'})
    set_hl('StringDelimiter',{bg=u})
    ---CAT6
    set_hl('Special',{fg=p.pink})
    set_hl('Field',{fg=p.purple})
    set_hl('Argument',{bg=u})
    set_hl('Attribute',{bg=u})
    set_hl('Identifier',{fg=p.purple})
    set_hl('Property',{bg=u})
    set_hl('Function',{fg=p.func})
    set_hl('FunctionBuiltin',{bg=u})
    set_hl('KeywordFunction',{bg=u})
    set_hl('Method',{bg=u})
    ---CAT7
    set_hl('Type',{fg=p.green})
    set_hl('Typedef',{fg=p.block})
    set_hl('TypeBuiltin',{bg=u})
    set_hl('Class',{bg=u})
    set_hl('StorageClass',{fg=p.purple})
    set_hl('Structure',{fg=p.pink})
    ---CAT8
    set_hl('Regexp',{bg=u})
    set_hl('RegexpSpecial',{bg=u})
    set_hl('RegexpDelimiter',{bg=u})
    set_hl('RegexpKey',{bg=u})
    ---CAT9
    set_hl('CommentURL',{bg=u})
    set_hl('CommentLabel',{bg=u})
    set_hl('CommentSection',{bg=u})
    set_hl('Noise',{bg=u})
    ---DIFF
    set_hl('DiffAdd',{bg=invgreen})
    set_hl('DiffChange',{bg=p.mainbg})
    set_hl('DiffDelete',{bg=invred})
    set_hl('DiffText',{bg=invyellow})
    ---LSP
    set_hl('DiagnosticFloatingError',{link='ErrorMsg'})
    set_hl('DiagnosticFloatingWarn',{link='WarningMsg'})
    set_hl('DiagnosticFloatingInfo',{link='MoreMsg'})
    set_hl('DiagnosticFloatingHint',{link='Msg'})
    set_hl('DiagnosticDefaultError',{link='ErrorMsg'})
    set_hl('DiagnosticDefaultWarn',{link='WarningMsg'})
    set_hl('DiagnosticDefaultInfo',{link='MoreMsg'})
    set_hl('DiagnosticDefaultHint',{link='Msg'})
    set_hl('DiagnosticVirtualTextError',{link='ErrorMsg'})
    set_hl('DiagnosticVirtualTextWarn',{link='WarningMsg'})
    set_hl('DiagnosticVirtualTextInfo',{link='MoreMsg'})
    set_hl('DiagnosticVirtualTextHint',{link='Msg'})
    set_hl('DiagnosticSignError',{link='ErrorMsg'})
    set_hl('DiagnosticSignWarning',{link='WarningMsg'})
    set_hl('DiagnosticSignInformation',{link='MoreMsg'})
    set_hl('DiagnosticSignHint',{link='Msg'})
    vim.cmd.highlight('LspHighlight guibg=none guifg=none gui=underline guisp='..p.pink)
    set_hl('LspReferenceText',{link='LspHighlight'})
    set_hl('LspReferenceRead',{link='LspHighlight'})
    set_hl('LspReferenceWrite',{link='LspHighlight'})
    ---Spell
    set_hl('SpellBad',{undercurl=true,sp='#b73424',bold=true})
    set_hl('SpellCap',{undercurl=true,sp='#0030c7',bold=true})
    set_hl('SpellLocal',{undercurl=true,sp='#7050c7',bold=true})
    set_hl('SpellRare',{undercurl=true,sp='#50a007',bold=true})
    ---TS
    set_hl('@field',{link='Field'})
    set_hl('@variable',{link='Variable'})
    set_hl('@text.strong',{link='Bold'})
    set_hl('@text.emphasis',{link='Italic'})
    ---LSP
    set_hl('@lsp.type.variable',{link='Variable'})
    ---EXT
    set_hl('DashboardHeader',{link='Title'})
    set_hl('DashboardDesc',{link='Include'})
    ---TERM
    vim.g.terminal_color_0='#000000'
    vim.g.terminal_color_1='#FF0000'
    vim.g.terminal_color_2='#00FF00'
    vim.g.terminal_color_3='#FFFF00'
    vim.g.terminal_color_4='#0000FF'
    vim.g.terminal_color_5='#FF00FF'
    vim.g.terminal_color_6='#00FFFF'
    vim.g.terminal_color_7='#EEEEEE'
    vim.g.terminal_color_8='#888888'
    vim.g.terminal_color_9='#FF8888'
    vim.g.terminal_color_10='#88FF88'
    vim.g.terminal_color_11='#FFFF88'
    vim.g.terminal_color_12='#8888FF'
    vim.g.terminal_color_13='#FF88FF'
    vim.g.terminal_color_14='#88FFFF'
    vim.g.terminal_color_15='#FFFFFF'
end
return M
