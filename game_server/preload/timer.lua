local PriorityQueue = require "priority_queue"
local Timer = class()


function Timer:ctor()
    self.__timer_id = 0
    self.__callbacks = {}
    self.__timedefault = 0
end

function Timer:fix_timestamp(timestamp)
    self.__timedefault = timestamp - os.time() 
end

function Timer:get_current_time()
    return os.time() + self.__timedefault
end

function Timer:init()
    self.__priority_queue = PriorityQueue.new()
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
    local timestamp = self:get_current_time()
    local head_score = self.__priority_queue:get_head_score()
    if not head_score or head_score <= 0 then return end
    if head_score > timestamp then return end
    local loop_actions = {}
    self.__priority_queue:pop_head_members(timestamp,function(member)
        local timer_id = tonumber(member)
        local action = self.__callbacks[timer_id]
        self.__callbacks[timer_id] = nil
        local callback = action.callback
        local ok,err = xpcall(callback,debug.traceback)
        if not ok then syslog.err(err) end
        local loop = action.loop or false
        if not loop then return end
        loop_actions[#loop_actions+1] = action
    end)
    if table.empty(loop_actions) then return end
    syslog.debug("loop_actions",table.tostring(loop_actions))
    for _,action in ipairs(loop_actions) do
        self:register(action.interval,action.callback,action.loop)
    end
end

function Timer:register(interval, callback, loop)
    assert(type(interval) == "number")
    interval = math.max(interval,0)
    local timestamp = interval + self:get_current_time()
    local timer_id = self:get_timer_id()
    local action = {}
    action.callback = callback
    action.interval = interval
    action.loop = loop or false
    self.__callbacks[timer_id] = action
    self.__priority_queue:add(timestamp,timer_id)
    return timer_id
end

function Timer:unregister(timer_id)
    self.__priority_queue:rem(timer_id)
end

return Timer