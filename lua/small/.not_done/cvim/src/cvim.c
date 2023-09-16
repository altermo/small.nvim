#include "lua51.h"
typedef struct luaL_Reg {
    const char *name;
    lua_CFunction func;
} luaL_Reg;
enum cvim_internal_is {
    cvim_internal_IS_TABLE=1,
    cvim_internal_IS_NIL=2,
    cvim_internal_IS_NONE=4,
    cvim_internal_IS_FUNC=8,
};
void cvim_internal_check (lua_State *L,int idx,enum cvim_internal_is is){
    /*TODO combine check functions into one*/
    if (cvim_internal_IS_TABLE&is)
        if (lua_istable(L,idx))
            return;
    if (cvim_internal_IS_NIL&is)
        if (lua_isnil(L,idx))
            return;
    if (cvim_internal_IS_NONE&is)
        if (lua_isnone(L,idx))
            return;
    if (cvim_internal_IS_FUNC&is)
        if (lua_isfunction(L,idx))
            return;
    lua_pushstring(L,"argument is wrong type");
    lua_error(L);
};
void cvim_internal_check_exsists(lua_State *L,int idx){
    if (lua_isnone(L,idx)){
        lua_pushstring(L,"argument is none");
        lua_error(L);
    }
}
static int cvim_tbl_contains(lua_State *L){
    /*TODO: implement caching */
    /*TODO: make checking/default-assigning shorter*/
    /*args: t:table,value:any,opts:table|none*/
    cvim_internal_check(L,1,cvim_internal_IS_TABLE);
    cvim_internal_check_exsists(L,2);
    cvim_internal_check(L,3,cvim_internal_IS_TABLE|cvim_internal_IS_NIL|cvim_internal_IS_NONE);
    if (lua_isnil(L,3)) lua_pop(L,1);
    if (lua_isnone(L,3)) lua_newtable(L);
    lua_getfield(L,3,"predicate");
    int predicate=lua_toboolean(L,4);
    if (predicate) cvim_internal_check(L,2,cvim_internal_IS_FUNC);
    lua_pushnil(L);
    for (;lua_next(L,1);){
        if (!predicate&&lua_equal(L,2,-1)){
            lua_pushboolean(L,1);
            return 1;
        }else if (predicate){
            lua_pushvalue(L,2);
            lua_pushvalue(L,-2);
            lua_call(L,1,1);
            if (lua_toboolean(L,-1)){
                lua_pushboolean(L,1);
                return 1;
            };
            lua_pop(L,1);
        };
        lua_pop(L,1);
    };
    lua_pushboolean(L,0);
    return 1;
};
int luaopen_cvim(lua_State *L) {
    luaL_Reg reg[]={
        {"tbl_contains",cvim_tbl_contains},
        {NULL,NULL},
    };
    lua_newtable(L);
    for (luaL_Reg *l=reg;l->name!=NULL;l++){
        lua_pushcfunction(L,l->func);
        lua_setfield(L,-2,l->name);
    }
    return 1;
}
