local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local VERSION = "1.2.0"

local Util = require("@self/util")
local Help = require("@self/help")

local Color = Util.Color
local Log = Util.Log

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
		Log(`ropen.yaml already exists at: {targetPath}`)
		return
	end

	fs.writeFile(targetPath, template)

	Log(`{Color("ropen.yaml", "cyan", "yellow")} initialized at {targetPath}`)
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
			Log(Color("ropen.yaml not found in project.", "red"))
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
		Log(`{Color("ROpen", "yellow", "cyan")} {VERSION}`)
		return
	end

	if lower == "--placeid" then
		local placeId = process.args[2]
		if not placeId or not tonumber(placeId) then
			Log(Color("Usage: ropen --placeid <id>", "red"))
			return
		end
		Util.openPlace(tostring(placeId), tostring(placeId), placeId)
		return
	end

	if lower:match("%.rbxlx?$") and fs.isFile(arg) then
		Util.open(arg)
		local filename = arg:match("([^/\\]+)$") or arg
		Log(`{Color("Opening Place:", "yellow")} {Color(filename, "cyan")}`)
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
	Log(
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
		Log(Color(`Game not found: {gameInput}`, "red"))
		return
	end

	if Util.isPlaceId(gameValue) then
		if placeInput then
			Log(Color(`This game only has one place. {Color("Usage:", "blue", "cyan")} ropen {gameKey}`, "yellow"))
			return
		end

		Util.openPlace(gameKey, gameKey, gameValue)
		return
	end

	local singlePlaceKey, singlePlaceId = Util.getSinglePlaceFromTable(gameValue)

	if singlePlaceKey then
		if placeInput and placeInput:lower() ~= singlePlaceKey:lower() then
			Log(Color(`Place not found: {placeInput}`, "red"))
			return
		end

		Util.openPlace(gameKey, singlePlaceKey, singlePlaceId)
		return
	end

	if not placeInput then
		Log(`{Color("Usage:", "blue", "cyan")} ropen <game>/<place>`)
		return
	end

	local placeKey, placeId = Util.findKeyInsensitive(gameValue, placeInput)

	if not placeId then
		Log(Color(`Place not found: {placeInput}`, "red"))
		return
	end

	Util.openPlace(gameKey, placeKey, placeId)
	return
end

local gameOptions = Util.orderGames(Config, localPath, globalPath)

local gameIndex = stdio.prompt("select", Color("Select Game:", "purple", "reset"), gameOptions)
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

local placeOptions = Util.orderPlaces(gameValue, gameName, localPath, globalPath)

local placeIndex = stdio.prompt("select", Color("Select Place:", "purple", "reset"), placeOptions)
if not placeIndex then
	return
end

local placeName = placeOptions[placeIndex]
local placeId = gameValue[placeName]

Util.openPlace(gameName, placeName, placeId)
