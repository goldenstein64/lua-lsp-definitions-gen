local json = require("dkjson").use_lpeg()
local compile = require("compile")
local lfs = require("lfs")

local ENUM_PATH_FORMAT = "out/enum/%s.lua"

local REQUEST_PATH_FORMAT = "out/routes/%s.lua"
local REQUEST_DIR_FORMAT = "out/routes/%s"

local REQUEST_READ_FORMAT = [[
local register = require("lsp.register")

---@param params lsp.Request.%s.params
---@return lsp.Response.%s.result
register["%s"] = function(params) end
]]

local REQUEST_WRITE_FORMAT = [[
local request = require("lsp.request")

---@return boolean, lsp.Response.%s.result | lsp.Response.%s.error
function request.%s(params)
	return request("%s", params)
end
]]

local NOTIFICATION_PATH_FORMAT = "out/routes/%s.lua"
local NOTIFICATION_DIR_FORMAT = "out/routes/%s"

local NOTIFICATION_READ_FORMAT = [[
local register = require("lsp.register")

---@param params lsp.Notification.%s.params
---@return nil -- notifications don't expect a response
register["%s"] = function(params) end
]]

local NOTIFICATION_WRITE_FORMAT = [[
local notify = require("lsp.notify")

---@return lsp.Notification.%s.params
function notify.%s() end
]]

local NOTIFICATION_READ_WRITE_FORMAT = [[
local register = require("lsp.register")
local notify = require("lsp.notify")

---@return lsp.Notification.%s.params
function notify.%s() end

---@param params lsp.Notification.%s.params
---@return nil -- notifications don't expect a response
register["%s"] = function(params) end
]]

---@param path string
local function ensureDir(path)
	local workingPath = ""
	for folderName in path:gmatch("[^/]+") do
		if workingPath == "" then
			workingPath = folderName
		else
			workingPath = workingPath .. "/" .. folderName
		end
		local s, err = lfs.mkdir(workingPath)
		assert(s or err == "File exists", err)
	end
end

local object do
	local data = assert(io.open("data/metaModel.json"))
	local content = data:read("a")

	---@type lspm.MetaModel
	object = assert(json.decode(content, 1, json.null))
end

local definitions, enums = compile:metamodel(object)

ensureDir("out") do
	local definitionsFile = assert(io.open("out/lsp.d.lua", "w"))
	definitionsFile:write(tostring(definitions))
	definitionsFile:close()
end

ensureDir("out/enum") do
	for name, buffer in pairs(enums) do
		local outFile = assert(io.open(ENUM_PATH_FORMAT:format(name), "w"))
		outFile:write(tostring(buffer))
		outFile:close()
	end
end

ensureDir("out/routes") do
	do
		for _, request in ipairs(object.requests) do
			local method = request.method
			local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
			local methodName = method:gsub("%$/", ""):gsub("/", "_")
			local moduleName = method:match("/([^/]+)$")
			local parentPath
			if moduleName then
				parentPath = assert(method:match("^(.+)/[^/]+$"), "parent path not found")
				ensureDir(REQUEST_DIR_FORMAT:format(parentPath))
			else
				moduleName = method
			end

			local dir = request.messageDirection
			local content
			if dir == "clientToServer" then
				content = REQUEST_READ_FORMAT:format(methodTypeName, methodTypeName, method)
			elseif dir == "serverToClient" then
				content = REQUEST_WRITE_FORMAT:format(methodTypeName, methodTypeName, methodName, method)
			else
				error(string.format("unhandled message direction '%s'", dir))
			end

			local requestPath = REQUEST_PATH_FORMAT:format(method)
			local requestFile = assert(io.open(requestPath, "w"))
			requestFile:write(content)
			requestFile:close()
		end
	end

	do
		for _, notification in ipairs(object.notifications) do
			-- generate a file in routes
			local method = notification.method
			local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
			local methodName = method:gsub("%$/", ""):gsub("/", "_")
			local moduleName = method:match("/([^/]+)$")
			if moduleName then
				local parentPath = assert(method:match("^(.+)/[^/]+$"), "parent path not found")
				ensureDir(NOTIFICATION_DIR_FORMAT:format(parentPath))
			else
				moduleName = method
			end


			local dir = notification.messageDirection
			local content
			if dir == "clientToServer" then
				content = NOTIFICATION_READ_FORMAT:format(methodTypeName, method)
			elseif dir == "serverToClient" then
				content = NOTIFICATION_WRITE_FORMAT:format(methodTypeName, methodName)
			else
				content = NOTIFICATION_READ_WRITE_FORMAT:format(methodTypeName, methodName, methodTypeName, method)
			end

			local notificationFile = assert(io.open(NOTIFICATION_PATH_FORMAT:format(method), "w"))
			notificationFile:write(content)
			notificationFile:close()
		end
	end
end
