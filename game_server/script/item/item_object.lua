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
    self.__item_id = item_object.item_id
    self.__item_index = item_object.item_index
    self.__item_count = item_object.item_count
    local item_attrs = item_object.item_attrs or {}
    self:load_item_attrs(item_attrs)
end

function ItemObject:load_item_attrs(item_attrs)
    for _, attr in pairs(item_attrs) do
        self.__item_attrs[attr.attr_key] = attr.attr_value or attr.attr_string
    end
end

function ItemObject:dump_item_object()
    local item_object = {}
    item_object.item_id = self.__item_id
    item_object.item_index = self.__item_index
    item_object.item_count = self.__item_count
    item_object.item_attrs = self:dump_item_attrs()
    return item_object
end

function ItemObject:dump_item_attrs()
    local item_attrs = {}
    for attr_key,attr_value in pairs(self.__item_attrs) do
        table.insert(item_attrs,pack_data_attr(attr_key,attr_value))
    end
    return item_attrs
end

function ItemObject:update_data_attrs(data_attrs)
    local item_attrs = {}
    for attr_key,attr_value in pairs(data_attrs) do
        if attr_key == ITEM_KEYS.ITEM_COUNT then
            self.__item_count = attr_value
        else
            self.__item_attrs[attr_key] = attr_value
        end
        table.insert(item_attrs,pack_data_attr(attr_key,attr_value))
    end
    self.__role_object:send_request("update_item_data_attrs",{item_id=self.__item_id,item_attrs = item_attrs})
end

return ItemObject