--[[
    @desc 
    author:{author}
    time:2022-05-13 24:31:13
]]

local ClassObject = class()

function ClassObject:ctor(xx)
    self.__xx = xx
end

function ClassObject:init()
end

return ClassObject