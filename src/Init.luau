local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local VERSION = "0.0.2"

local Util = require("@self/util")
local Help = require("@self/help")

local Color = Util.Color

local localPath = Util.resolveLocalPath()
local globalPath = Util.getGlobalPath()

local template = [[Crossroads:
  Lobby: 1818 # place id
  Arena: 1818 # place id

YourGame: 1818 # placeid]]

local arg = process.args[1]

if arg and arg:lower() == "init" then
	local isGlobal = process.args[2] == "--global"

	local targetPath = isGlobal and globalPath or "./ropen.yaml"

	if fs.isFile(targetPath) then
		print("ropen.yaml already exists at:", targetPath)
		return
	end

	fs.writeFile(targetPath, template)

	print(`{Color("ropen.yaml", "cyan", "yellow")} initialized at {targetPath}`)
	return
end

if arg and (arg:lower() == "edit" or arg:lower() == "e") then
	local isGlobal = process.args[2] == "--global"

	local targetPath = isGlobal and globalPath or localPath

	if not targetPath then
		if isGlobal then
			fs.writeFile(globalPath, template)
			targetPath = globalPath
		else
			print(Color("ropen.yaml not found in project.", "red"))
			return
		end
	end

	Util.openInEditor(targetPath)
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

	if lower == "--placeid" then
		local placeId = process.args[2]
		if not placeId then
			print(Color("Usage: ropen --placeId <id>", "red"))
			return
		end
		Util.openPlace(placeId, placeId, placeId)
		return
	end
end

local Config = {}

if globalPath and fs.isFile(globalPath) then
	local globalConfig = serde.decode("yaml", fs.readFile(globalPath))
	Config = Util.mergeConfigs(Config, globalConfig)
end

if localPath and fs.isFile(localPath) then
	local localConfig = serde.decode("yaml", fs.readFile(localPath))
	Config = Util.mergeConfigs(Config, localConfig)
end

if next(Config) == nil then
	print(
		Color(
			`No config found. Run \`{Color("ropen init", "cyan", "red")}\` or \`{Color(
				"ropen init --global",
				"cyan",
				"red"
			)}\``,
			"red"
		)
	)
	return
end

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
