.PHONY: default clean

TOP=$(PWD)
LUA_CLIB_PATH ?= luaclib
CC ?= gcc
LUA_INC ?= skynet/3rd/lua
CFLAGS = -g -O2 -Wall -I$(LUA_INC)
SHARED := -fPIC --shared
PLAT ?= linux

default : skynet/skynet $(LUA_CLIB_PATH)/cjson.so $(LUA_CLIB_PATH)/log.so $(LUA_CLIB_PATH)/web.so $(LUA_CLIB_PATH)/skiplist.so

skynet/Makefile :
	git submodule update --init

skynet/skynet : skynet/Makefile
	cd $(TOP)
	cd skynet && $(MAKE) $(PLAT)

$(LUA_CLIB_PATH)/skiplist.so: 3rd/lua-zset/skiplist.h 3rd/lua-zset/skiplist.c 3rd/lua-zset/lua-skiplist.c | $(LUA_CLIB_PATH)
	cd $(TOP)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-zset $^ -o $@

$(LUA_CLIB_PATH)/cjson.so : 3rd/lua-cjson/lua_cjson.c 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c | $(LUA_CLIB_PATH)
	cd $(TOP)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-cjson $^ -o $@ 

$(LUA_CLIB_PATH)/log.so : 3rd/lua-log/lua-log.c | $(LUA_CLIB_PATH)
	cd $(TOP)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/web.so : 3rd/lua-web/webclient.c | $(LUA_CLIB_PATH)
	cd $(TOP)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-web $^ -o $@ -lcurl

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)
	
clean :
	rm -f $(LUA_CLIB_PATH)/*.so
	cd skynet && $(MAKE) clean
