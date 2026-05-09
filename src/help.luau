local Help
local Util = require("../src/util")
local Color = Util.Color

function Help(VERSION)
	print(Color("ROpen", "yellow", "cyan") .. " " .. VERSION)
	print(Color("Open Roblox Studio places quickly from the terminal.", "blue"))
	print("")

	print(Color("OPENING A PLACE", "purple", "cyan"))
	print("  " .. Color("ropen", "cyan", "reset") .. "				Pick game/place interactively")
	print("  " .. Color("ropen <game>/<place>", "cyan", "reset") .. "		Open a place from a game")
	print("  " .. Color("ropen <game>", "cyan", "reset") .. "			Open a single place from a game")
	print("  " .. Color("ropen <placeId>", "cyan", "reset") .. "		Open by numeric Roblox place ID")
	print("  " .. Color("ropen --placeid <id>", "cyan", "reset") .. "		Same as a bare place ID (explicit)")
	print("  " .. Color("ropen <file.rbxl>", "cyan", "reset") .. "		Open a local .rbxl / .rbxlx file")
	print("")

	print(Color("CONFIGURATION", "purple", "cyan"))
	print(
		"  "
			.. Color("ropen init [--global]", "cyan", "reset")
			.. "		Create ropen.yaml (project directory or user-wide)"
	)
	print("  " .. Color("ropen edit [--global]", "cyan", "reset") .. "		Open ropen.yaml in your editor")
	print("")

	print(Color("OTHER", "purple", "cyan"))
	print("  " .. Color("-h, --help", "cyan", "reset") .. "			Show this help message")
	print("  " .. Color("-v, --version", "cyan", "reset") .. "			Show CLI version")
	print("")

	print(Color("EXAMPLES", "purple", "cyan"))
	print("  ropen init")
	print("  ropen Crossroads/Lobby")
	print("  ropen YourGame")
	print("  ropen")
	print("  ropen 1818")
	print("  ropen ./path/to/file.rbxl")
	Util.Log("")
end

return Help
