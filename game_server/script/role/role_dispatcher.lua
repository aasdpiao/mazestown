--[[
    @desc 
    author:{author}
    time:2022-04-10 10:41:08
]]

local ClassObject = class()

function ClassObject:ctor(xx)
    self.__xx = xx
end

function ClassObject:init()
end

return ClassObject