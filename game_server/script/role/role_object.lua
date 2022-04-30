local ItemManager = require "item.item_manager"


local RoleObject = class()

function RoleObject:ctor(role_manager)
    self.__role_manager = role_manager

    self.__c2s_protocal = {}
    self.__s2c_protocal = {}
end

function RoleObject:init()
    self.__item_manager = ItemManager.new(self)
    self.__item_manager:init()
end

function RoleObject:register_c2s_callback(dispatcher,request_name,callback)
    self.__c2s_protocal[request_name] = {dispatcher = dispatcher,callback = callback}
end

function RoleObject:register_s2c_callback(dispatcher,response_name,callback)
    self.__s2c_protocal[response_name] = {dispatcher = dispatcher,callback = callback}
end

function RoleObject:get_handle_request(request_name)
    return self.__c2s_protocal[request_name]
end

function RoleObject:get_handle_response(response_name)
    return self.__s2c_protocal[response_name]
end

return RoleObject