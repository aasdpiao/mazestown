local ItemObject = class()

function ItemObject:ctor(role_object)
    self.__role_object = role_object
    self.__item_manager = role_object:get_item_ruler():get_item_manager()

    self.__item_id = 0
    self.__item_index = 0
    self.__item_count = 0

    self.__item_attrs = {}
end

function ItemObject:get_item_entry()
    return self.__item_manager:get_item_entry(self.__item_index)
end

function ItemObject:load_item_object(item_object)
    
end

return ItemObject