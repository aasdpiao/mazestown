local ItemUnit = class()

function ItemUnit:ctor(item_index)
    self.__item_index = item_index
    self.__item_count = 0

    self.__item_attrs = {}
end

function ItemUnit:init()
end

function ItemUnit:get_item_entry()
    return self.__item_manager:get_item_entry(self.__item_index)
end

function ItemUnit:set_itam_attr(attr_key,attr_value)
    if attr_key == ITEM_KEYS.ITEM_COUNT then
        self.__item_count = attr_value
    else
        self.__item_attrs[attr_key] = attr_value
    end
end

function ItemUnit:get_item_attr(attr_key,default_value)
    if attr_key == ITEM_KEYS.ITEM_COUNT then
        return self.__item_count
    else
        return self.__item_attrs[attr_key] or default_value
    end
end

return ItemUnit