local sprotoloader = require "sprotoloader"
local socketdriver = require "skynet.socketdriver"
local RoleObject = require "role.role_object"
local multicast = require "skynet.multicast"
local datacenter = require "skynet.datacenter"
local queue = require "skynet.queue"
local profile = require "skynet.profile"
local cjson = require "cjson"


local host = sprotoloader.load(MSG.c2s):host "package"
local request = host:attach (sprotoloader.load (MSG.s2c))

local TIMEOUT = 1 * 100 --断线重连时间2分钟
local SAVETIME = 30000   --存档时间 5分钟

local HEARTBEAT_TIME_MAX = 1000 -- 30秒钟未收到消息，则判断为客户端失联
local KICK_TIME_MAX = 12000

local cs = queue()
local gate
local account_id,client_fd
local role_object
local publish_mc
local time_mc
local cancel_check_exit
local last_heartbeat_time = 0

local session = {}
local session_id = 0

function cancelable_timeout(ti, func)
	local function cb()
		if func then
			func()
		end
	end
	local function cancel()
		func = nil
	end
	skynet.timeout(ti, cb)
	return cancel
end

local function check_can_exit()
	if not role_object then return true end
	local cache_ruler = role_object:get_cache_ruler()
	if not cache_ruler then return true end
	local subscribe = cache_ruler:check_subscribe()
	return subscribe == 0
end

local function cancel_timer()
	if not cancel_check_exit then return end
	cancel_check_exit()
end

local function check_exit(timeout)
	timeout = timeout or TIMEOUT
	cancel_timer()
	cancel_check_exit = cancelable_timeout(timeout,function()
		if check_can_exit() then
			role_object:save_player()
			if not gate then return end
			skynet.error(string.format("account_id:%d exit [%s]",account_id,skynet.address(skynet.self())))
			skynet.send(gate, "lua", "logout", account_id)
		else
			return check_exit()
		end
	end)
end

local function heartbeat_check ()
	local t = last_heartbeat_time + HEARTBEAT_TIME_MAX - skynet.now ()
	local kick_t = last_heartbeat_time + KICK_TIME_MAX - skynet.now ()
	if t <= 0 then
		if role_object and last_heartbeat_time > 0 and kick_t <= 0 then
			check_exit()
			LOG_WARNING("heartbeat_check : %d is kick last:%d now:%d ", role_object:get_account_id(),last_heartbeat_time,skynet.now())
		elseif role_object then
			role_object:send_request("heartbeat",{})
		end
		return skynet.timeout (HEARTBEAT_TIME_MAX, heartbeat_check)
	else
		collectgarbage("step",100)
		return skynet.timeout (t, heartbeat_check)
	end
end

local function send_message(message)
	if not client_fd then return end
	local package = string.pack (">s2", message)
	socketdriver.send(client_fd, package)
end

local function send_request (name, args)
	session_id = session_id + 1
	local msg = request (name, args, session_id)
	if not SEND_FITER[name] then
		syslog.warningf ("send message(%s)", name) 
		syslog.warningf ("args: \n%s",table.tostring(args))
	end
	send_message(msg)
	session[session_id] = { name = name, args = args }
end

-- 处理客户端来的请求消息
local function handle_request (name, args, response)
	local handle = role_object:get_handle_request(name)
	if handle then
		local ok, ret = xpcall (handle.callback, debug.traceback, handle.dispatcher, args)
		if not ok then
			syslog.warningf ("handle message(%s) failed : %s", name, ret) 
			syslog.warningf ("args: \n%s",table.tostring(args))
		else
			if not RECV_FITER[name] then
				syslog.warningf ("handle message(%s)", name) 
				syslog.warningf ("args: \n%s",table.tostring(args))
				syslog.warningf ("return: \n%s",table.tostring(ret))
			end
			if response and ret then
				local message = response(ret)
				send_message(message)
			end
		end
	else
		syslog.warningf ("unhandled message : %s", name)
	end
end
-- 处理客户端来的返回消息
local function handle_response(id, args)
	local s = session[id]
	session[id] = nil
	if not s then
		syslog.warningf ("session %d not found", id)
		return
	end
	local handle = role_object:get_handle_response(s.name)
	if not handle then
		if not RESPONSE_FITER[s.name] then
			syslog.warningf ("unhandled response : %s", s.name)
		end
		return
	end
	local ok, ret = xpcall (handle.callback, debug.traceback, handle.dispatcher, s.args, args)
	if not ok then
		syslog.warningf ("handle response(%d-%s) failed : %s", id, s.name, ret) 
	end
end

local function handle_request_dispatcher(name, args, response)
	cs(function()
		profile.start()
		handle_request (name, args, response)
		local time = profile.stop()
		role_object:add_profile_time(name,time)
	end)
end

local function handle_response_dispatcher(id, args)
	cs(function()
		handle_response(id, args)
	end)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		last_heartbeat_time = skynet.now ()
		return host:dispatch (msg, sz)
	end,
	dispatch = function (_, __, type, ...)
		skynet.ignoreret()
		if type == "REQUEST" then
			handle_request_dispatcher(...)
		elseif type == "RESPONSE" then
			handle_response_dispatcher(...)
		end
	end,
}

local CMD = {}

function CMD.login(source, id, fd, server_id)
	if client_fd then
		socketdriver.close(client_fd)
	end
	STATISTICS_RECORD("agent : %d is login  fd:%d", id, fd)
	gate = source
	account_id = id
	client_fd = fd
	assert(account_id > 0)
	role_object = RoleObject.new(account_id, send_request, publish_mc)
	local ok,ret = xpcall (role_object.init, debug.traceback, role_object, 0)
	if not ok then
		LOG_INFO("agent : %d is traceback %s", account_id,ret)
		syslog.err(ret)
		if client_fd then
			socketdriver.close(client_fd)
		end
		return skynet.send(gate, "lua", "logout", account_id)
	end
	role_object:set_server_id(server_id)
	local timetamp = role_object:get_time_ruler():get_current_time()
	role_object:set_login_timestamp(timetamp)
	role_object:notify_role_login()
	local timestamp = role_object:get_time_ruler():get_current_time()
	SERVICE_NAME = ""..id
end

function CMD.reenter(source, id, fd, server_id)
	if client_fd then
		socketdriver.close(client_fd)
	end
	LOG_INFO("agent : %d is reenter  fd:%d", id, fd)
	gate = source
	role_object:set_offline(0)
	role_object:set_server_id(server_id)
	role_object:notify_role_login()
	account_id = id
	client_fd = fd
	cancel_timer()
	local timestamp = os.time()
	if role_object:get_time_ruler() then
		timestamp = role_object:get_time_ruler():get_current_time()
	end
	role_object:set_login_timestamp(timestamp)
	SERVICE_NAME = ""..id
end

function CMD.offline(source,id,server_id)
	STATISTICS_RECORD("agent : %d is offline", id)
	gate = source
	account_id = id
	assert(account_id > 0)
	role_object = RoleObject.new(account_id, send_request, publish_mc)
	local ok, ret = xpcall (role_object.init, debug.traceback, role_object, 1)
	if not ok then
		STATISTICS_RECORD("agent : %d is traceback %s", account_id,ret)
		syslog.err(ret)
		return skynet.send(gate, "lua", "logout", account_id)
	end
	role_object:set_server_id(server_id)
	SERVICE_NAME = ""..id
	check_exit(12000)
end

function CMD.debug(source,id,server_id)
	STATISTICS_RECORD("agent : %d is debug", id)
	gate = source
	account_id = id
	assert(account_id > 0)
	role_object = RoleObject.new(account_id, send_request, publish_mc)
	local ok ,ret = xpcall (role_object.init, debug.traceback, role_object, 1)
	if not ok then
		STATISTICS_RECORD("agent : %d is traceback %s", account_id,ret)
		syslog.err(ret)
		return skynet.send(gate, "lua", "logout", account_id)
	end
	role_object:set_server_id(server_id)
	SERVICE_NAME = ""..id
	cancel_timer()
end

function CMD.logout(source)
	STATISTICS_RECORD("agent : %s is logout", account_id)
	local online_time = role_object:get_online_time()
	role_object:unsubscribe()
	role_object:save_last_login_timestamp()
	role_object:notify_role_logout()
	role_object:save_player()
	role_object:set_offline(1)
	if online_time > 0 then
		local role_info = role_object:get_role_info()
		skynet.send("gamed","lua","update_account_role",role_info) 
	end
	check_exit()
end

function CMD.notice_update(source)
	if role_object then
		role_object:send_request("notice_update")
	end
end

function CMD.forbid_player(source, login, chat)
	if role_object then
		role_object:forbid_login(login)
		role_object:forbid_chat(chat)
		if login == 1 then 
			role_object:send_request("forbid_player")
		end
		if chat == 1 then 
			role_object:send_request("forbid_chat")
		end 
	end
end

function CMD.forbid_chat(source)
	if role_object then
		role_object:forbid_chat()
		role_object:send_request("forbid_chat")
	end
end

function CMD.approve_chat(source)
	if role_object then
		role_object:approve_chat()
	end
end

function CMD.kick(source)
	STATISTICS_RECORD("agent : %s is kick", account_id)
	local online_time = role_object:get_online_time()
	role_object:unsubscribe()
	role_object:save_player()
	role_object:kick_clent()
	role_object:set_offline(1)
	if online_time > 0 then 
		local role_info = role_object:get_role_info()
		skynet.send("gamed","lua","update_account_role",role_info) 
	end
end

function CMD.save(source)
	if role_object then
		role_object:save_player()
	end
end

function CMD.disconnect(source)
	STATISTICS_RECORD("agent : %s is disconnect", account_id)
	if role_object and role_object:check_first_logout() then
		local push_type = 8
		local account_id = role_object:get_account_id()
		local platformID = role_object:get_platform_uid()
	    local timestamp = role_object:get_time_ruler():get_current_time()
        role_object:add_push_timer_objects(account_id,push_type,platformID,timestamp)
	    role_object:finish_first_logout()
	end
	
	local online_time = role_object:get_online_time()
	role_object:unsubscribe()
	role_object:save_last_login_timestamp()
	role_object:notify_role_logout()
	role_object:save_player()
	role_object:set_offline(1)
	if online_time > 0 then 
		local role_info = role_object:get_role_info()
		skynet.send("gamed","lua","update_account_role",role_info) 
	end
	check_exit()
end

function CMD.handle_request(source,...)
	if not role_object then return end
	role_object:set_dirty(true)
	return role_object:get_cache_ruler():handle_request(...)
end

function CMD.query_player(source,option)
	if not role_object then return end
	return role_object:query_player(option)
end

function CMD.query_level()
	if not role_object then return end
	return role_object:get_event_ruler():get_prosperity_level()
end

function CMD.power_cmd(source,cmd,cmd_args)
	local func = admin_power[cmd]
	local result = 0
	if func then
		local args = string.split(cmd_args,"_")
		result = func(role_object,args)
	else
		syslog.err("cmd:"..cmd.." not callback")
	end
	return result
end

function CMD.send_mail(source,mail_object)
	if role_object then
		role_object:send_mail(mail_object)
	end
end

function CMD.operate_recharge(source,transaction_id,iap_index,orderno)
	if not role_object then return false end
	return role_object:operate_recharge(transaction_id,iap_index,orderno)
end

function CMD.receive_chat_message(source,message,player_info)
	if role_object then
		role_object:receive_chat_message(message,player_info)
	end
end

function CMD.publish_online_stranger(source,timestamp,message_type)
	if role_object then
		role_object:publish_online_stranger(timestamp,message_type)
	end
end

local function update()
	while true do
		skynet.sleep(SAVETIME)
		if role_object then
			role_object:save_player()
		end	
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command],"command not exist :"..command)
		skynet.ret(skynet.pack(f(source, ...)))
	end)
	local channel = datacenter.get "TIMESYNC"
	time_mc = multicast.new {
		channel = channel,
		dispatch = function (channel, source, timestamp)
			if not role_object then return end
			role_object:send_request("update_time",{timestamp=timestamp})
			role_object:get_time_ruler():update_time(timestamp)
			role_object:get_timer_ruler():update_time(timestamp)
		end
	}
	time_mc:subscribe()
	publish_mc = multicast.new()
	heartbeat_check()
	skynet.fork(update)
end)

skynet.info_func(function(...)
	if not role_object then return "agent not login" end
	return role_object:debug_info(...)
end)