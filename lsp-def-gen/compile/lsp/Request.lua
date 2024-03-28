local maybeMove = require("lsp-def-gen.compile.util.maybeMove")

---Represents a LSP request
---@class lspm.Request
---The direction in which this notification is sent in the protocol.
---The request's method name.
---@field method string
---The direction in which this request is sent in the protocol.
---@field messageDirection lspm.MessageDirection
---@field documentation? string
---Optional; a dynamic registration method if it different from the request's method.
---@field registrationMethod? string
---Optional; registration options if the request supports dynamic registration.
---@field registrationOptions? lspm.Type
---The parameter type(s) if any.
---@field params? lspm.Type | lspm.Type[]
---@field result lspm.Type
---@field errorData? lspm.Type
---Optional; partial result type if the request supports partial result reporting.
---@field partialResult? lspm.Type

---Indicates in which direction a message is sent in the protocol.
---@alias lspm.MessageDirection "clientToServer" | "serverToClient" | "both"

local messageDirectionMap = {
	clientToServer = "Client --> Server",
	serverToClient = "Client <-- Server",
	both = "Client --> Server --> Client"
}

local REG_METHOD_FORMAT = "---Registration Method: `%s`"
local REQUEST_FORMAT = "lsp.Request.%s"
local REQUEST_CLASS_FORMAT = "---@class %s : lsp.Request"
local PARAMS_NAME_FORMAT = "%s.field"
local PARAMS_FIELD_FORMAT = "---@field params %s.params"
local PARAMS_ALIAS_FORMAT = "---@alias %s.params %s"

local RESULT_FIELD_FORMAT = "---@field result? %s.result"
local ERROR_FIELD_FORMAT = "---@field error? %s.error"

local RESULT_ALIAS_FORMAT = "---@alias %s.result %s"
local ERROR_ALIAS_FORMAT = "---@alias %s.error %s"

local RESPONSE_FORMAT = "lsp.Response.%s"
local RESPONSE_CLASS_FORMAT = "---@class %s : lsp.Response"

---@param compile compile_lsp
---@param obj lspm.Request
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj)
	local superBuffer = compile:buffer("\n\n")

	local methodTypeName = obj.method:gsub("%$", "_"):gsub("/", "-")
	local requestTypeName = REQUEST_FORMAT:format(methodTypeName)
	local responseTypeName = RESPONSE_FORMAT:format(methodTypeName)

	local classes = {}
	local docBuffer = compile:buffer("\n")
	if obj.documentation then
		docBuffer:append(compile:docComment(obj.documentation))
		docBuffer:append("---")
	end

	docBuffer:append("---Message Direction: " .. messageDirectionMap[obj.messageDirection])
	if obj.registrationMethod then
		docBuffer:append("---")
		docBuffer:append(REG_METHOD_FORMAT:format(obj.registrationMethod))
	end

	if obj.registrationOptions then
		local compiled, subClasses = compile:type(obj.registrationOptions, requestTypeName .. ".registrationOptions")
		docBuffer:append("---")
		docBuffer:append("---Registration Options:")
		docBuffer:append("---@see " .. tostring(compiled))
		maybeMove(subClasses, classes)
	end

	local requestBuffer = compile:buffer("\n")

	requestBuffer:append(docBuffer)
	requestBuffer:append(REQUEST_CLASS_FORMAT:format(requestTypeName))
	requestBuffer:append(string.format("---@field method %q", obj.method))

	local paramsField = PARAMS_FIELD_FORMAT:format(requestTypeName)
	requestBuffer:append(paramsField)

	superBuffer:append(requestBuffer)

	do
		local aliasBuffer = compile:buffer("\n")
		local params = obj.params
		local paramType
		if params then
			local compiled, subClasses = compile:type(params, PARAMS_NAME_FORMAT:format(requestTypeName))
			maybeMove(subClasses, classes)
			paramType = compiled
		else
			paramType = "cjson.null?"
		end
		aliasBuffer:append(docBuffer)
		aliasBuffer:append(PARAMS_ALIAS_FORMAT:format(requestTypeName, paramType))
		superBuffer:append(aliasBuffer)
	end

	local responseBuffer = compile:buffer("\n")
	responseBuffer:append(docBuffer)
	responseBuffer:append(RESPONSE_CLASS_FORMAT:format(responseTypeName))
	responseBuffer:append(RESULT_FIELD_FORMAT:format(responseTypeName))
	responseBuffer:append(ERROR_FIELD_FORMAT:format(responseTypeName))
	superBuffer:append(responseBuffer)

	do
		local aliasBuffer = compile:buffer("\n")
		local compiled, subClasses = compile:type(obj.result, responseTypeName .. ".__result")
			maybeMove(subClasses, classes)
			aliasBuffer:append(RESULT_ALIAS_FORMAT:format(responseTypeName, compiled))
			table.insert(classes, aliasBuffer)
	end

	do
		local aliasBuffer = compile:buffer("\n")
		local errorType
		if obj.errorData then
			local compiled, subClasses = compile:type(obj.errorData, responseTypeName .. ".__error")
			maybeMove(subClasses, classes)
			errorType = compiled
		else
			errorType = "lsp.ResponseError"
		end
		aliasBuffer:append(ERROR_ALIAS_FORMAT:format(responseTypeName, errorType))
		table.insert(classes, aliasBuffer)
	end


	return superBuffer, #classes > 0 and classes or nil
end
