local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local VERSION = "0.0.1"

local function resolveROpenPath()
	if fs.isFile("./ropen.yaml") then
		return "./ropen.yaml"
	end

	local excludedDirectories = {
		[".git"] = true,
		["node_modules"] = true,
		["Packages"] = true,
		["ServerPackages"] = true,
		["DevPackages"] = true,
	}

	local function find(dir)
		local path = dir .. "/ropen.yaml"
		if fs.isFile(path) then
			return path
		end

		if fs.isDir(dir) then
			for _, entryName in ipairs(fs.readDir(dir)) do
				if not excludedDirectories[entryName] then
					local entryPath = dir .. "/" .. entryName

					if fs.isDir(entryPath) then
						local found = find(entryPath)
						if found then
							return found
						end
					end
				end
			end
		end

		return nil
	end

	return find(".")
end

local ROpenPath = resolveROpenPath()

local function findKeyInsensitive(tbl, key)
	local lower = key:lower()

	for k, v in tbl do
		if type(k) == "string" and k:lower() == lower then
			return k, v
		end
	end

	return nil
end

local function isPlaceId(value)
	return type(value) == "number" or tonumber(value) ~= nil
end

local function getSinglePlaceFromTable(tbl)
	local foundKey = nil
	local foundValue = nil

	for k, v in tbl do
		if k ~= "UniverseId" and isPlaceId(v) then
			if foundKey then
				return nil
			end
			foundKey = k
			foundValue = v
		end
	end

	return foundKey, foundValue
end

local function Color(text, c1, c2)
	return `{stdio.color(c1)}{text}{c2 and stdio.color(c2) or ""}`
end

local function openPlace(gameKey, placeKey, placeId)
	local url = `roblox-studio:1+task:EditPlace+placeId:{placeId}+universeId:0`

	local osName = process.os

	if osName == "windows" then
		process.exec("", { 'explorer "' .. url .. '"' }, { shell = true })
	elseif osName == "macos" then
		process.exec("open", { url })
	else
		process.exec("xdg-open", { url })
	end

	if gameKey == placeKey then
		print(`{Color("Opening Place:", "yellow")} {Color(gameKey, "cyan")}`)
	else
		print(`{Color("Opening Place:", "yellow")} {Color(gameKey, "cyan", "yellow")} → {Color(placeKey, "cyan")}`)
	end
end

local function Help()
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

local arg = process.args[1]

if arg and arg:lower() == "init" then
	if ROpenPath then
		print("ropen.yaml already exists at:", ROpenPath)
		return
	end

	local template = [[
Crossroads:
  Lobby: 1818 # place id
  Arena: 1818 # place id

YourGame: 1818 # placeid
]]

	fs.writeFile("./ropen.yaml", template)

	print(`{Color("ropen.yaml", "cyan", "yellow")} initialized`)
	return
end

if arg then
	local lower = arg:lower()

	if lower == "-h" or lower == "--help" or lower == "help" then
		Help()
		return
	end

	if lower == "-v" or lower == "--version" then
		print(`{Color("ROpen", "yellow", "cyan")} {VERSION}`)
		return
	end
end

if not ROpenPath then
	print(Color(`ropen.yaml not found, run \`{Color("ropen init", "cyan", "red")}\` to create one.`, "red"))
	return
end

local Config = serde.decode("yaml", fs.readFile(ROpenPath))

if arg then
	if process.args[2] then
		arg = table.concat(process.args, " ")
	end

	local parts = arg:split("/")
	local gameInput = parts[1]
	local placeInput = parts[2]

	local gameKey, gameValue = findKeyInsensitive(Config, gameInput)

	if not gameValue then
		print(Color("Game not found:", "red"), gameInput)
		return
	end

	if isPlaceId(gameValue) then
		if placeInput then
			print(Color("This game only has one place. Usage:", "yellow"), gameKey)
			return
		end

		openPlace(gameKey, gameKey, gameValue)
		return
	end

	local singlePlaceKey, singlePlaceId = getSinglePlaceFromTable(gameValue)

	if singlePlaceKey then
		if placeInput and placeInput:lower() ~= singlePlaceKey:lower() then
			print(Color("Place not found:", "red"), placeInput)
			return
		end

		openPlace(gameKey, singlePlaceKey, singlePlaceId)
		return
	end

	if not placeInput then
		print(`{Color("Usage:", "blue", "cyan")} ropen <game>/<place>`)
		return
	end

	local placeKey, placeId = findKeyInsensitive(gameValue, placeInput)

	if not placeId then
		print(Color("Place not found:", "red"), placeInput)
		return
	end

	openPlace(gameKey, placeKey, placeId)
	return
end

local gameOptions = {}

for gameName in Config do
	table.insert(gameOptions, gameName)
end

local gameIndex = stdio.prompt("select", Color("Select Game:", "purple", "cyan"), gameOptions)
if not gameIndex then
	return
end

local gameName = gameOptions[gameIndex]
local gameValue = Config[gameName]

if isPlaceId(gameValue) then
	openPlace(gameName, gameName, gameValue)
	return
end

local singlePlaceKey, singlePlaceId = getSinglePlaceFromTable(gameValue)

if singlePlaceKey then
	openPlace(gameName, singlePlaceKey, singlePlaceId)
	return
end

local placeOptions = {}

for placeName, value in gameValue do
	if placeName ~= "UniverseId" and isPlaceId(value) then
		table.insert(placeOptions, placeName)
	end
end

local placeIndex = stdio.prompt("select", Color("Select Place:", "purple", "cyan"), placeOptions)
if not placeIndex then
	return
end

local placeName = placeOptions[placeIndex]
local placeId = gameValue[placeName]

openPlace(gameName, placeName, placeId)
