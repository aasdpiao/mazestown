local ItemDispatcher = require "item.item_dispatcher"
local ItemManager = require "item.item_manager"

local ItemRuler = class()

function ItemRuler:ctor(role_object)
    self.__role_object = role_object
end

function ItemRuler:init()
    self.__item_dispatcher = ItemDispatcher.new(self)
    self.__item_dispatcher:init()

    self.__item_manager = ItemManager.new(self)
    self.__item_manager:init()
end

return ItemRuler