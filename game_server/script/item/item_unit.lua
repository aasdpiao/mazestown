local ItemUnit = class()

function ItemUnit:ctor(item_index)
    self.__item_index = item_index
    
end

function ItemUnit:init()
end

return ItemUnit