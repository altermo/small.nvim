local cvim=require'cvim'
local rep=100000
local t=_G
local val=_G
local function f1() cvim.tbl_contains(t,val) end
local function f2() vim.tbl_contains(t,val) end
local t1=os.clock()
for _=1,rep do f1() end
vim.pprint(os.clock()-t1)
local t2=os.clock()
for _=1,rep do f2() end
vim.pprint(os.clock()-t2)
vim.tbl_contains=cvim.tbl_contains
