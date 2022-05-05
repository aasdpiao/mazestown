--[[
    @desc 
    author:{author}
    time:2022-05-03 13:52:33
]]

local ClassObject = class()

function ClassObject:ctor(xx)
    self.__xx = xx
end

function ClassObject:init()
end

return ClassObject