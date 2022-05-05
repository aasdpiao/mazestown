local ItemDispatcher = require "item.item_dispatcher"
local ItemManager = require "item.item_manager"
local ItemObject = require "item.item_object"
local BackpackPocket = require "pocket.pocket_backpack"
local StorePocket = require "pocket.pocket_store"

local ItemRuler = class()

function ItemRuler:ctor(role_object)
    self.__role_object = role_object

    self.__item_pockets = {}
end

function ItemRuler:init()
    self.__item_dispatcher = ItemDispatcher.new(self)
    self.__item_dispatcher:init()

    self.__item_manager = ItemManager.new(self)
    self.__item_manager:init()

    self.__item_pockets[POCKET_KEYS.POCKET_TYPE_BACKPACK] = BackpackPocket.new(self.__role_object, POCKET_KEYS.POCKET_TYPE_BACKPACK)
    self.__item_pockets[POCKET_KEYS.POCKET_TYPE_STORE] = StorePocket.new(self.__role_object, POCKET_KEYS.POCKET_TYPE_STORE)

    for _, pocket in pairs(self.__item_pockets) do
        pocket:init()
    end
end

function ItemRuler:get_item_pocket(pocket_type)
    return self.__item_pockets[pocket_type]
end

function ItemRuler:get_item_object(item_id,pocket_type)
    if pocket_type then
        local item_pocket = self:get_item_pocket(pocket_type)
        if not item_pocket then return end
        return item_pocket:get_item_object(item_id)
    end
    for _, item_pocket in ipairs(self.__item_pockets) do
        local item_object = item_pocket:get_item_object(item_id)
        if item_object then return item_object end
    end
end

function ItemRuler:get_pocket_free_space_count(pocket_type)
    pocket_type = pocket_type or POCKET_KEYS.POCKET_TYPE_BACKPACK
    local item_pocket = self.get_item_pocket(pocket_type)
    return item_pocket:get_free_count()
end

function ItemRuler:add_item_object(item_unit)
    
end

return ItemRuler