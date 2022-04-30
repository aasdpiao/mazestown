local ItemOperate = class()

function ItemOperate:ctor(role_object)
    self.__role_object = role_object
    self.__item_ruler = role_object:get_item_ruler()
    self.__item_manager = self.__item_manager:get_item_manager()
end

function ItemOperate:upgrade_item_object(item_id,item_level)
    local item_object = self.__item_ruler:get_item_object(item_id)
    if not item_object then
        LOG_ERROR("item_id:%d not exist errr:%s",item_id,error_msg(GAME_ERROR.item_object_not_exist))
        return GAME_ERROR.item_object_not_exist
    end
    if not item_object:check_can_upgrade(item_level) then
        LOG_ERROR("item_id:%d item_level:%d not can upgrade errr:%s",item_id,item_level,error_msg(GAME_ERROR.item_object_cant_upgrade))
        return GAME_ERROR.item_object_cant_upgrade
    end
    local levelup_entry = self.__item_manager:get_item_levelup_entry(item_id,item_level)
    if not levelup_entry then
        LOG_ERROR("item_id:%d item_level:%d not exist errr:%s",item_id,item_level,error_msg(GAME_ERROR.config_not_exist))
        return GAME_ERROR.config_not_exist
    end
    local formula = levelup_entry.formula or {}
    for item_index,item_count in pairs(formula) do
        if not self.__role_object:check_item_enough(item_index,item_count) then
            LOG_ERROR("item_id:%d item_level:%d not enough item_index:%d item_count:%d errr:%s",item_id,item_level,item_index,item_count,error_msg(GAME_ERROR.item_not_enough))
            return GAME_ERROR.item_not_enough
        end
    end
    for item_index,item_count in pairs(formula) do
        self.__role_object:consume_item_object(item_index,item_count,CONSUME_CODE.no_consume)
    end
    item_object:upgrade_item_object(item_level)
    return 0
end

return ItemOperate