local random_const = require "random_const"
local random = math.random


function get_random_int(mix,max)
	return random(mix,max)
end

function check_random_weight(weight,times)
    local fix_weight = (random_const[math.ceil(weight)] or 0) * times
    local random_value = get_random_int(1,10000000) * 0.0001
    return random_value <= fix_weight
end

function check_random_percent(weight)
	local random_weight = get_random_int(1,100)
	return random_weight <= weight
end

function get_random_value_in_weight(total_weight, value_weight_list)
	if total_weight == 0 or #value_weight_list == 0 then return end
	local random_weight = get_random_int(1,total_weight)
	for i,value in pairs(value_weight_list) do
		if value[2] < random_weight then
			random_weight = random_weight - value[2]
		else
			return value[1]
		end
	end
end

function get_random_list_in_weight(total_weight,value_weight_list,count)
	if total_weight == 0 or #value_weight_list == 0 then return {} end
	local result = {}
	if #value_weight_list <= count then
		for k,v in pairs(value_weight_list) do
			local value = v[1]
			table.insert( result,value)
		end
		return result
	end
	local copy_value_weight_list = copy(value_weight_list)
	for i=1,count do
		local random_weight = get_random_int(1,total_weight)
		for i,value in pairs(copy_value_weight_list) do
			if value[2] < random_weight then
				random_weight = random_weight - value[2]
			else
				table.insert(result,value[1])
				total_weight = total_weight - value[2]
				copy_value_weight_list[i] = nil
				if total_weight <= 0 then return result end
				break
			end
		end
	end
	return result
end

function choice_random_list(random_list)
	local random_index = get_random_int(1,#random_list)
	return random_list[random_index]
end