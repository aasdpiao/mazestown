local TimerRuler = class()

function TimerRuler:ctor(role_object)
    self.__role_object = role_object

    self.__timer_id = 0

    self.__daily_callbacks = {}
    self.__week_callbacks = {}
end

function TimerRuler:init()
    self.__timer_manager = Timer.new()
    self.__timer_manager:init()

    local timestamp = self.__role_object:get_time_ruler():get_current_time()
    local interval_timestamp = get_interval_timestamp(timestamp)
    local week_timestamp = get_week_interval(timestamp)
    local week_timeout = week_timestamp - timestamp
    local timeout = interval_timestamp - timestamp
    self:register(timeout,function()
        self:trigger_daily_timeout()
    end)
    self:register(week_timeout,function()
        self:trigger_week_timeout()
    end)
end

function TimerRuler:get_timer_id()
    self.__timer_id = self.__timer_id + 1
    return self.__timer_id
end

function TimerRuler:trigger_daily_timeout()
    for _,callback in pairs(self.__daily_callbacks) do
        local ok,err = xpcall(callback,debug.traceback)
        if not ok then syslog.err(err) end
    end
    local timestamp = self.__role_object:get_time_ruler():get_current_time()
    local interval_timestamp = get_interval_timestamp(timestamp)
    local timeout = interval_timestamp - timestamp
    return self:register(timeout,function()
        self:trigger_daily_timeout()
        LOG_STATISTICS("每日刷新:%s",get_epoch_time(timestamp))
    end)
end

function TimerRuler:trigger_week_timeout()
    for _,callback in pairs(self.__week_callbacks) do
        local ok,err = xpcall(callback,debug.traceback)
        if not ok then syslog.err(err) end
    end
    local timestamp = self.__role_object:get_time_ruler():get_current_time()
    local week_timestamp = get_week_interval(timestamp)
    local week_timeout = week_timestamp - timestamp
    return self:register(week_timeout,function()
        self:trigger_week_timeout()
        LOG_STATISTICS("每周刷新:%s",get_epoch_time(timestamp))
    end)
end

function TimerRuler:update_time(timestamp)
    self.__timer_manager:fix_timestamp(timestamp)
end

function TimerRuler:register(interval, callback, loop)
    return self.__timer_manager:register(interval, callback, loop)
end

function TimerRuler:unregister(timer_id)
    self.__timer_manager:unregister(timer_id)
end

function TimerRuler:register_daily_callback(callback)
    local timer_id = self:get_timer_id()
    self.__daily_callbacks[timer_id] = callback
    return timer_id
end

function TimerRuler:unregister_daily_callback(timer_id)
    self.__daily_callbacks[timer_id] = nil
end

function TimerRuler:register_week_callback(callback)
    local timer_id = self:get_timer_id()
    self.__week_callbacks[timer_id] = callback
    return timer_id
end

function TimerRuler:unregister_week_callback(timer_id)
    self.__week_callbacks[timer_id] = nil
end

return TimerRuler