local Util = {}

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

function Util.getHomePath()
	local osName = process.os

	if osName == "windows" then
		return process.env.USERPROFILE
	elseif osName == "macos" or osName == "linux" then
		return process.env.HOME
	end

	error("Unsupported OS: " .. tostring(osName))
end

function Util.getGlobalPath()
	local home = Util.getHomePath()
	return home .. "/ropen.yaml"
end

function Util.openInEditor(path)
	local editor = process.env.EDITOR

	if editor and editor ~= "" then
		process.exec(editor, { path })
		return
	end

	local osName = process.os

	if osName == "windows" then
		process.exec("notepad", { path })
	elseif osName == "macos" then
		process.exec("open", { "-e", path })
	else
		process.exec("nano", { path })
	end
end

function Util.mergeConfigs(base, override)
	local result = table.clone(base)

	for k, v in override do
		if type(v) == "table" and type(result[k]) == "table" then
			result[k] = Util.mergeConfigs(result[k], v)
		else
			result[k] = v
		end
	end

	return result
end

local UTF8_BOM = string.char(0xEF, 0xBB, 0xBF)

local function stripUtf8Bom(text)
	return (text:gsub("^" .. UTF8_BOM, ""))
end

local function yamlLines(text)
	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	return lines
end

local function yamlIndent(line)
	return #(line:match("^(%s*)") or "")
end

-- Parse a YAML mapping line (trimmed, no leading indent). Returns key and value after ":".
local function yamlParseMappingLine(trimmed)
	if not trimmed or trimmed == "" or trimmed:match("^#") then
		return nil, nil
	end

	local quotedKey, quotedRest = trimmed:match('^"([^"]*)"%s*:%s*(.*)$')
	if quotedKey then
		return quotedKey, quotedRest
	end

	local singleKey, singleRest = trimmed:match("^'([^']*)'%s*:%s*(.*)$")
	if singleKey then
		return singleKey, singleRest
	end

	local colon = trimmed:find(":")
	if not colon then
		return nil, nil
	end

	local key = trimmed:sub(1, colon - 1):match("^%s*(.-)%s*$")
	if not key or key == "" then
		return nil, nil
	end

	return key, trimmed:sub(colon + 1)
end

local function yamlMappingKeyAtStart(trimmed)
	local key = yamlParseMappingLine(trimmed)
	return key
end

local function yamlInlinePlaceIdValue(valuePart)
	return valuePart ~= nil and valuePart:match("^%s*%d") ~= nil
end

local function yamlOrderedGameKeys(content)
	if content == nil or content == "" then
		return {}
	end

	local keys = {}
	local seen = {}
	for _, line in ipairs(yamlLines(stripUtf8Bom(content))) do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed == "" or trimmed:match("^#") or yamlIndent(line) ~= 0 then
			continue
		end

		local key = yamlMappingKeyAtStart(trimmed)
		if key and not seen[key] then
			seen[key] = true
			table.insert(keys, key)
		end
	end

	return keys
end

function Util.yamlOrderedPlaceKeys(content, gameKey)
	if content == nil or content == "" or gameKey == nil or gameKey == "" then
		return {}
	end

	local lines = yamlLines(stripUtf8Bom(content))
	local want = tostring(gameKey):lower()

	local sectionIndex
	for i, line in ipairs(lines) do
		if yamlIndent(line) == 0 then
			local trimmed = line:match("^%s*(.-)%s*$")
			local key = yamlMappingKeyAtStart(trimmed)
			if key and key:lower() == want then
				sectionIndex = i
				break
			end
		end
	end

	if not sectionIndex then
		return {}
	end

	local header = lines[sectionIndex]
	local _, headerValue = yamlParseMappingLine(header:match("^%s*(.-)%s*$"))
	if yamlInlinePlaceIdValue(headerValue) then
		return {}
	end

	local keys = {}
	local blockIndent

	for i = sectionIndex + 1, #lines do
		local line = lines[i]
		local indent = yamlIndent(line)
		local rest = line:sub(indent + 1)

		if rest == "" or rest:match("^#") then
			continue
		end

		if indent == 0 and yamlMappingKeyAtStart(rest) then
			break
		end

		local key = yamlMappingKeyAtStart(rest)
		if not key or indent == 0 then
			continue
		end

		if blockIndent == nil then
			blockIndent = indent
		end

		if indent == blockIndent and key:lower() ~= "universeid" then
			table.insert(keys, key)
		end
	end

	return keys
end

--- Games as listed in yaml files (local first, then global-only keys), then any extras from `config`.
function Util.orderGames(config, localPath, globalPath)
	local ordered = {}
	local seen = {}

	local function addFromFile(path)
		if not path or not fs.isFile(path) then
			return
		end
		local content = fs.readFile(path)
		for _, yamlKey in yamlOrderedGameKeys(content) do
			local actualKey = Util.findKeyInsensitive(config, yamlKey)
			if actualKey and not seen[actualKey] then
				seen[actualKey] = true
				table.insert(ordered, actualKey)
			end
		end
	end

	addFromFile(localPath)
	addFromFile(globalPath)

	for k in config do
		if not seen[k] then
			table.insert(ordered, k)
		end
	end

	return ordered
end

--- Places for prompts: yaml order (local then global), matching `gameValue` entries.
function Util.orderPlaces(gameValue, gameName, localPath, globalPath)
	local ordered = {}
	local seen = {}

	local function addFromFile(path)
		if not path or not fs.isFile(path) then
			return
		end
		local content = fs.readFile(path)
		for _, yamlKey in Util.yamlOrderedPlaceKeys(content, gameName) do
			local actualKey = Util.findKeyInsensitive(gameValue, yamlKey)
			if actualKey and tostring(actualKey):lower() ~= "universeid" and not seen[actualKey] then
				local val = gameValue[actualKey]
				if Util.isPlaceId(val) then
					seen[actualKey] = true
					table.insert(ordered, actualKey)
				end
			end
		end
	end

	addFromFile(localPath)
	addFromFile(globalPath)

	for placeName, value in gameValue do
		if tostring(placeName):lower() ~= "universeid" and Util.isPlaceId(value) and not seen[placeName] then
			table.insert(ordered, placeName)
		end
	end

	return ordered
end

function Util.resolveLocalPath()
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

function Util.findKeyInsensitive(tbl, key)
	local lower = tostring(key):lower()

	for k, v in tbl do
		if tostring(k):lower() == lower then
			return k, v
		end
	end

	return nil
end

function Util.isPlaceId(value)
	return type(value) == "number" or tonumber(value) ~= nil
end

function Util.getSinglePlaceFromTable(tbl)
	local foundKey = nil
	local foundValue = nil

	for k, v in tbl do
		if tostring(k):lower() ~= "universeid" and Util.isPlaceId(v) then
			if foundKey then
				return nil
			end
			foundKey = k
			foundValue = v
		end
	end

	return foundKey, foundValue
end

function Util.Color(text, c1, c2)
	return `{stdio.color(c1)}{text}{c2 and stdio.color(c2) or ""}`
end

function Util.Log(...)
	print(..., stdio.color("reset"))
end

function Util.open(target)
	local osName = process.os

	if osName == "windows" then
		process.exec("", { 'explorer "' .. target .. '"' }, { shell = true })
	elseif osName == "macos" then
		process.exec("open", { target })
	else
		process.exec("xdg-open", { target })
	end
end

function Util.openPlace(gameKey, placeKey, placeId)
	local url = `roblox-studio:1+task:EditPlace+placeId:{placeId}+universeId:0`
	Util.open(url)

	if gameKey == placeKey then
		Util.Log(`{Util.Color("Opening Place:", "yellow")} {Util.Color(gameKey, "cyan")}`)
	else
		Util.Log(
			`{Util.Color("Opening Place:", "yellow")} {Util.Color(gameKey, "cyan", "yellow")} → {Util.Color(
				placeKey,
				"cyan"
			)}`
		)
	end
end

return Util
