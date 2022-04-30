local Timer = class()

function Timer:ctor()
    self.__timer_id = 0
    self.__callbacks = {}
    self.__timestamp = 0
    self.__cancel = {}
    self.__timedefault = 0
    self.__timestep = 0
    self.__epoch_timestamp = {}
end

function Timer:fix_timestamp(timestamp)
    self.__timedefault = timestamp - os.time() 
end

function Timer:init()
    self.__timestamp = os.time()
    self.__timestep = os.time() 
    skynet.fork(function()
        self:update()
    end)
end

function Timer:get_timer_id()
    self.__timer_id = self.__timer_id + 1
    return self.__timer_id
end

function Timer:update()
    while true do
        self:on_time_out()
        skynet.sleep(100)
    end
end

function Timer:on_time_out()
    self.__timestamp = os.time() + self.__timedefault
    local callbacks = {}
    for i=self.__timestep,self.__timestamp do
        local cb = self.__callbacks[i]
        if cb then
            table.contain(callbacks,cb)
            self.__callbacks[i] = nil
        end
    end
    self.__timestep = self.__timestamp
    for timer_id, action in pairs(callbacks) do
        local callback = action.callback
        local interval = action.interval
        local loop = action.loop
        if loop then
            self:loop_call(timer_id,interval,callback)
        else
            self.__cancel[timer_id] = nil
            self.__epoch_timestamp[timer_id] = nil
        end
        callback()
    end
end

function Timer:register(interval, callback, loop)
    assert(type(interval) == "number")
    interval = math.max(interval,0)
    local timestamp = self.__timestamp + interval
    local timer_id = self:get_timer_id()
    if not self.__callbacks[timestamp] then
        self.__callbacks[timestamp] = {}
    end
    local callbacks = self.__callbacks[timestamp]
    local action = {}
    action.callback = callback
    action.interval = interval
    action.loop = loop or false
    callbacks[timer_id] = action
    self.__cancel[timer_id] = function()
        callbacks[timer_id] = nil
        self.__epoch_timestamp[timer_id] = nil
    end
    self.__epoch_timestamp[timer_id] = timestamp
    return timer_id
end

function Timer:loop_call(timer_id,interval,callback)
    local timestamp = self.__timestamp + interval
    if not self.__callbacks[timestamp] then
        self.__callbacks[timestamp] = {}
    end
    local callbacks = self.__callbacks[timestamp]
    local action = {}
    action.callback = callback
    action.interval = interval
    action.loop = true
    callbacks[timer_id] = action
    self.__cancel[timer_id] = function()
        callbacks[timer_id] = nil
        self.__epoch_timestamp[timer_id] = nil
    end
    self.__epoch_timestamp[timer_id] = timestamp
end

function Timer:unregister(timer_id)
    local callcel = self.__cancel[timer_id]
    if not callcel then return end
    callcel()
end

function Timer:get_epoch_timestamp(timer_id)
    return self.__epoch_timestamp[timer_id]
end

function Timer:debug()
    return self.__epoch_timestamp
end

function Timer:reset()
    self.__callbacks = {}
    self.__cancel = {}
end

return Timer