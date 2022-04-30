local ItemOperate = require "item.item_operate"

local ItemDispatcher = class()

function ItemDispatcher:ctor(role_object)
    self.__role_object = role_object
    self.__item_operate = ItemOperate.new(role_object)
end

function ItemDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(self,request_name,callback)
end

function ItemDispatcher:register_s2c_callback(request_name,callback)
    self.__role_object:register_s2c_callback(self,request_name,callback)
end

function ItemDispatcher:init()
    --客户端请求服务器
    self:register_c2s_callback("upgrade_item_object",self.dispatcher_c2s_upgrade_item_object)
    --服务器请求客户端
    self:register_s2c_callback("update_item_object",self.dispatcher_s2c_update_item_object)
    --其他玩家请求我
    self:register_handle_callback("update_item_list",self.dispatcher_s2c_update_item_list)
end

function ItemDispatcher.dispatcher_c2s_upgrade_item_object(args)
    local item_id = args.item_id or 0
    local item_level = args.item_level or 0
    local result = self.__item_operate:upgrade_item_object(item_id,item_level)
    return {result = result}
end

function ItemDispatcher.dispatcher_s2c_update_item_object(args1, args2)
end

return ItemDispatcher