-------------------table-----------------------------------
function table.tostring(root)
    if root == nil then
        return "nil"
    elseif type(root) == "number" then
        return tostring(root)
    elseif type(root) == "string" then
        return root
    end
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
            else
                if type(v) == "string" then
                    table.insert(temp,"+" .. key .. " [\"" .. tostring(v).."\"]")
                else
                    table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
                end
                
            end
        end
        return table.concat(temp,"\n"..space)
    end
    return (_dump(root, "",""))
end

function table.getn(t)
    local n = 0
    for k,v in pairs(t) do
        n = n + 1
    end
    return n
end

-------------------string-----------------------------------
local mode = "[\0\b\n\r\t\26\\\'\"]"
local replace = {
    ['\0'] = "\\0",
    ['\b'] = "\\b",
    ['\n'] = "\\n",
    ['\r'] = "\\r",
    ['\t'] = "\\t",
    ['\26'] = "\\Z",
    ['\\'] = "\\\\",
    ["'"] = "\\'",
    ['"'] = '\\"',
}
function string.escape(s)
    return string.gsub(s, mode, replace)
end


function copy(object)
    if not object then return object end
    local new = {}
    for k, v in pairs(object) do
        local t = type(v)
        if t == "table" then
            new[k] = copy(v)
        elseif t == "userdata" then
            new[k] = copy(v)
        else
            new[k] = v
        end
    end
    return new
end

--时间计算相关
--打印时间
function get_epoch_time(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end
--获取今日结束时间
function get_daily_dawn_time(timestamp)
    local temp = os.date("*t", timestamp)
    return os.time{year=temp.year, month=temp.month, day=temp.day, hour=24}
end
--获取这周的结束时间
function get_weekly_dawn_time(timestamp)
    local temp = os.date("*t", timestamp)
    return os.time{year=temp.year, month=temp.month, day=temp.day, hour=24} + ((8 - temp.wday) % 7) * SECONDS_PER_DAY
end
--获取这个月的结束时间
function get_monthly_dawn_time(timestamp)
    local temp = os.date("*t", timestamp)
    return os.time{year=temp.year, month=temp.month + 1, day=1, hour=0}
end

function pack_data_attr(attr_key,attr_value)
   local attr_object = {attr_key=attr_key}
   if type(attr_value) == "number" then
        attr_object.attr_value = attr_value
   elseif type(attr_value) == "string" then
        attr_object.attr_string = attr_value
   end
   return attr_object
end