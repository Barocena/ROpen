local Help
local Util = require("../src/util")
local Color = Util.Color

function Help(VERSION)
	print(Color("ROpen", "yellow", "cyan") .. " " .. VERSION)
	print(Color("Open Roblox Studio places quickly from the terminal.", "blue"))
	print("")

	print(Color("USAGE", "purple", "cyan"))
	print("  ropen <game>/<place>")
	print("  ropen")
	print("  ropen <command>")
	print("")

	print(Color("COMMANDS", "purple", "cyan"))
	print("  " .. Color("init", "cyan", "reset") .. "			Initialize a ropen.yaml template")
	print("  " .. Color("-h, --help", "cyan", "reset") .. "		Show this help message")
	print("  " .. Color("-v, --version", "cyan", "reset") .. "		Show CLI version")
	print("")

	print(Color("EXAMPLES", "purple", "cyan"))
	print("  ropen Crossroads/Lobby")
	print("  ropen YourGame")
	print("  ropen")
	print("")
end

return Help
