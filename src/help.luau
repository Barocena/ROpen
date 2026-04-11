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
	print("  ropen --placeid <id>")
	print("  ropen <command>")
	print("")

	print(Color("COMMANDS", "purple", "cyan"))
	print("  " .. Color("init", "cyan", "reset") .. "			Initialize a local ropen.yaml")
	print("  " .. Color("init --global", "cyan", "reset") .. "		Initialize a global ropen.yaml")
	print("  " .. Color("edit", "cyan", "reset") .. "			Open local ropen.yaml in editor")
	print("  " .. Color("edit --global", "cyan", "reset") .. "		Open global ropen.yaml in editor")
	print("  " .. Color("-h, --help", "cyan", "reset") .. "		Show this help message")
	print("  " .. Color("-v, --version", "cyan", "reset") .. "		Show CLI version")
	print("")

	print(Color("EXAMPLES", "purple", "cyan"))
	print("  ropen Crossroads/Lobby")
	print("  ropen YourGame")
	print("  ropen")
	print("  ropen --placeid 1818")
	print("  ropen init --global")
	print("  ropen edit --global")
	print("")
end

return Help
