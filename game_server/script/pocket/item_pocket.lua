local ItemPocket = class()

function ItemPocket:ctor(role_object,pocket_type)
    self.__role_object = role_object
    self.__pocket_type = pocket_type
    self.__pocket_volume = 0
    self.__item_object_dict = {}       --item_id : item_object
    self.__item_listener = {}          --物品监听管理器
end

function ItemPocket:init()
    self.__pocket_volume = get_define_default(self.__pocket_type)
end

function ItemPocket:get_pocket_volume()
    return self.__pocket_volume
end

function ItemPocket:get_pocket_type()
    return self.__pocket_type
end

function ItemPocket:is_pocket_full()
    return table.getn(self.__item_object_dict) >= self.__pocket_volume
end

function ItemPocket:get_item_object(item_id)
    return self.__item_object_dict[item_id]
end

function ItemPocket:get_free_count()
    return self.__pocket_volume - table.getn(self.__item_object_dict)
end

function ItemPocket:append()
    
end

return ItemPocket