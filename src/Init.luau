local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local VERSION = "0.0.1"

local Util = require("@self/util")
local Help = require("@self/help")

local ROpenPath = Util.resolveROpenPath()
local Color = Util.Color

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
		Help(VERSION)
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

	local gameKey, gameValue = Util.findKeyInsensitive(Config, gameInput)

	if not gameValue then
		print(Color("Game not found:", "red"), gameInput)
		return
	end

	if Util.isPlaceId(gameValue) then
		if placeInput then
			print(Color("This game only has one place. Usage:", "yellow"), gameKey)
			return
		end

		Util.openPlace(gameKey, gameKey, gameValue)
		return
	end

	local singlePlaceKey, singlePlaceId = Util.getSinglePlaceFromTable(gameValue)

	if singlePlaceKey then
		if placeInput and placeInput:lower() ~= singlePlaceKey:lower() then
			print(Color("Place not found:", "red"), placeInput)
			return
		end

		Util.openPlace(gameKey, singlePlaceKey, singlePlaceId)
		return
	end

	if not placeInput then
		print(`{Color("Usage:", "blue", "cyan")} ropen <game>/<place>`)
		return
	end

	local placeKey, placeId = Util.findKeyInsensitive(gameValue, placeInput)

	if not placeId then
		print(Color("Place not found:", "red"), placeInput)
		return
	end

	Util.openPlace(gameKey, placeKey, placeId)
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

if Util.isPlaceId(gameValue) then
	Util.openPlace(gameName, gameName, gameValue)
	return
end

local singlePlaceKey, singlePlaceId = Util.getSinglePlaceFromTable(gameValue)

if singlePlaceKey then
	Util.openPlace(gameName, singlePlaceKey, singlePlaceId)
	return
end

local placeOptions = {}

for placeName, value in gameValue do
	if placeName ~= "UniverseId" and Util.isPlaceId(value) then
		table.insert(placeOptions, placeName)
	end
end

local placeIndex = stdio.prompt("select", Color("Select Place:", "purple", "cyan"), placeOptions)
if not placeIndex then
	return
end

local placeName = placeOptions[placeIndex]
local placeId = gameValue[placeName]

Util.openPlace(gameName, placeName, placeId)
