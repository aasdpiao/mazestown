local skiplist = require "skiplist.c"
local mt = {}
mt.__index = mt

function mt:add(score, member)
    member = tostring(member)
    local old = self.tbl[member]
    if old then
        if old == score then
            return
        end
        self.sl:delete(old, member)
    end
    self.sl:insert(score, member)
    self.tbl[member] = score
end

function mt:rem(member)
    member = tostring(member)
    local score = self.tbl[member]
    if score then
        self.sl:delete(score, member)
        self.tbl[member] = nil
    end
end

function mt:count()
    return self.sl:get_count()
end

function mt:dump()
    self.sl:dump()
end

function mt:get_head_score()
    local head_list = self.sl:get_rank_range(1, 1)
    if table.empty(head_list) then return end
    local member = head_list[1] or 0
    return self.tbl[member] or 0
end

function mt:pop_head_members(score,delete_handler)
    local members = self.sl:get_score_range(0, score) or {}
    local rank = #members
    if rank <= 0 then return end
    local delete_function = function(member)
        self.tbl[member] = nil
        if delete_handler then
            delete_handler(member)
        end
    end
    return self.sl:delete_by_rank(1, rank, delete_function)
end

local M = {}

function M.new()
    local obj = {}
    obj.sl = skiplist()
    obj.tbl = {}
    return setmetatable(obj, mt)
end

return M

