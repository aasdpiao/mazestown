--[[
    @desc 
    author:{author}
    time:2022-05-01 22:49:29
]]

local ClassObject = class()

function ClassObject:ctor(xx)
    self.__xx = xx
end

function ClassObject:init()
end

return ClassObject