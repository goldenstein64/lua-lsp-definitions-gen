local Buffer = require("lsp-def-gen.compile.util.Buffer")

local INDENT_CHAR = '\t'

local compile_lib = {}

---@param sep? string
---@return Buffer
function compile_lib:buffer(sep)
	return Buffer(sep)
end

---@param buffer table
---@return Buffer
function compile_lib:bufferOf(buffer)
	setmetatable(buffer, Buffer)
	return buffer
end

---@param str string
---@return fun(): string
local function lines(str)
	return string.gmatch(str, "[^\n]+")
end

---@param str string
---@param indent? integer
---@return Buffer
function compile_lib:docComment(str, indent)
	indent = indent or 0
	local buffer = Buffer("\n")
	for line in lines(str) do
		buffer:append(INDENT_CHAR:rep(indent) .. "---" .. line)
	end

	return buffer
end

---@param obj lspm.MetaModel
function compile_lib:metamodel(obj)
	local buffer = self:buffer('\n\n')

	buffer:append("---@meta")

	local responseBuffer = self:buffer('\n\n')
	responseBuffer:append("---@class lsp*.Response\nlocal response = {}")
	local requestBuffer = self:buffer('\n')
	requestBuffer:append("---@class lsp*.Request")
	local notifyBuffer = self:buffer('\n')
	notifyBuffer:append("---@class lsp*.Notify")

	for _, request in ipairs(obj.requests) do
		local dir = request.messageDirection
		local method = request.method
		local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
		-- local methodName = method:gsub("%$/", ""):gsub("/", "_")

		if dir == "clientToServer" then
			local responseField = self:buffer("\n")
			if request.documentation then
				responseField:append(self:docComment(request.documentation))
			end
			responseField:append(string.format("---@param params lsp.Request.%s.params", methodTypeName))
			responseField:append(string.format("---@return lsp.Response.%s.result", methodTypeName))
			responseField:append(string.format("response[\"%s\"] = function(params) end", method))
			responseBuffer:append(responseField)
		elseif dir == "serverToClient" then
			local requestOverload = string.format(
				"---@overload fun(method: \"%s\", params: lsp.Request.%s.params): lsp.Response.%s.result",
				method, methodTypeName, methodTypeName
			)
			requestBuffer:append(requestOverload)
		else
			error("unhandled direction: " .. tostring(dir))
		end
	end

	for _, notif in ipairs(obj.notifications) do
		local dir = notif.messageDirection
		local method = notif.method
		local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
		local needsResponse = dir == "clientToServer" or dir == "both"
		local needsNotif = dir == "serverToClient" or dir == "both"

		if needsResponse then
			local responseField = self:buffer("\n")
			if notif.documentation then
				responseField:append(self:docComment(notif.documentation))
			end
			responseField:append(string.format("---@param params lsp.Notification.%s.params", methodTypeName))
			responseField:append(string.format("response[\"%s\"] = function(params) end", method))
			responseBuffer:append(responseField)
		end

		if needsNotif then
			local notifyOverload = string.format(
				"---@overload fun(method: \"%s\", params: lsp.Notification.%s.params)",
				method, methodTypeName
			)
			notifyBuffer:append(notifyOverload)
		end
	end

	buffer:append(responseBuffer)
	buffer:append(requestBuffer)
	buffer:append(notifyBuffer)
	return buffer
end

return compile_lib
