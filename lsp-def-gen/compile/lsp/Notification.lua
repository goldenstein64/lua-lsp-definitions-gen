local maybeMove = require("lsp-def-gen.compile.util.maybeMove")


---Represents a LSP notification
---@class lspm.Notification
---The direction in which this notification is sent in the protocol.
---@field messageDirection lspm.MessageDirection
---The request's method name.
---@field method string
---The parameter type(s) if any.
---@field params lspm.Type | lspm.Type[]
---@field documentation? string

local NOTIFICATION_FORMAT = "lsp.Notification.%s"
local NOTIFICATION_CLASS_FORMAT = "---@class %s : lsp.Notification"
local METHOD_FIELD_FORMAT = "---@field method %q"
local PARAMS_FIELD_FORMAT = "---@field params %s.params"

local PARAMS_ALIAS_FORMAT = "---@alias %s.params %s"

local messageDirectionMap = {
	clientToServer = "Client --> Server",
	serverToClient = "Client <-- Server",
	both = "Client <--> Server"
}

---@param compile compile_lsp
---@param obj lspm.Notification
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj)
	local superBuffer = compile:buffer("\n\n")

	local methodTypeName = obj.method:gsub("%$", "_"):gsub("/", "-")
	local notificationTypeName = NOTIFICATION_FORMAT:format(methodTypeName)

	local docBuffer = compile:buffer("\n")
	if obj.documentation then
		docBuffer:append(compile:docComment(obj.documentation))
		docBuffer:append("---")
	end
	docBuffer:append("---Message Direction: " .. messageDirectionMap[obj.messageDirection])

	local notificationBuffer = compile:buffer("\n")
	notificationBuffer:append(docBuffer)
	notificationBuffer:append(NOTIFICATION_CLASS_FORMAT:format(notificationTypeName))
	notificationBuffer:append(METHOD_FIELD_FORMAT:format(obj.method))
	notificationBuffer:append(PARAMS_FIELD_FORMAT:format(notificationTypeName))
	superBuffer:append(notificationBuffer)

	local classes = {} ---@type Buffer[]
	do
		local aliasBuffer = compile:buffer("\n")
		local paramsType
		if obj.params then
			local compiled, subClasses = compile:type(obj.params, notificationTypeName .. ".__params")
			maybeMove(subClasses, classes)
			paramsType = compiled
		else
			paramsType = "cjson.null?"
		end
		aliasBuffer:append(docBuffer)
		aliasBuffer:append(PARAMS_ALIAS_FORMAT:format(notificationTypeName, paramsType))
		superBuffer:append(aliasBuffer)
	end


	return superBuffer, #classes > 0 and classes or nil
end
