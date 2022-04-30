local skynet = require "skynet"
local lfs = require "lfs"
local print = syslog.debug

for file in lfs.dir("externals/protocal/c2s") do
	if file ~= "." and file ~= ".." then
		local f = io.open("externals/protocal/c2s/" .. file, "r")
		local content = f:read("*a")
		syslog.debug("name",file)
		syslog.debug("content",content)
		f:close()
	end
end

syslog.debug(table.tostring(c2s))


skynet.start(function()
	print("Main Server start")
	local console = skynet.newservice(
		"testmongodb", "127.0.0.1", 27017, "admin", "root", "bCrfAptbKeW8YoZU"
	)
	

	print("Main Server exit")
	skynet.exit()
end)
