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
	local lower = key:lower()

	for k, v in tbl do
		if type(k) == "string" and k:lower() == lower then
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
		if k ~= "UniverseId" and Util.isPlaceId(v) then
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

local function open(target)
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
	open(url)

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

function Util.openFileInExplorer(path)
	open(path)
end

return Util
