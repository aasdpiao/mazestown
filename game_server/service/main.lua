local skynet = require "skynet"

skynet.start(function()

	print("Main Server exit")
	skynet.exit()
end)
