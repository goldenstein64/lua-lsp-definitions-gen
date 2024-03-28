local NOTIFICATION_PATH_FORMAT = "out/routes/%s.lua"
local NOTIFICATION_DIR_FORMAT = "out/routes/%s"

local NOTIFICATION_READ_FORMAT = [[
---@param params lsp.Notification.%s.params
---@return nil -- notifications don't expect a response
return function(params) end
]]

---@param notif lspm.Notification
---@return string content
local function generateRouteContent(notif)
	local method = notif.method
	local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
	return NOTIFICATION_READ_FORMAT:format(methodTypeName, method)
end

---@param compile compile_lsp_lib
---@param notif lspm.Notification
---@return { response: Buffer?, notify: Buffer? } buffers
---@return string? routeContent
return function(compile, notif)
	local dir = notif.messageDirection
	local method = notif.method
	local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
	local needsResponse = dir == "clientToServer" or dir == "both"
	local needsNotif = dir == "serverToClient" or dir == "both"

	local result, routeContent = {}, nil
	if needsResponse then
		local responseField = compile:buffer("\n")
		if notif.documentation then
			responseField:append(compile:docComment(notif.documentation))
		end
		responseField:append(string.format("---@type fun(params: lsp.Notification.%s.params)", methodTypeName))
		responseField:append(string.format("response[\"%s\"] = nil", method))
		result.response = responseField
		routeContent = generateRouteContent(notif)
	end

	if needsNotif then
		local notifyField = compile:buffer("\n")
		if notif.documentation then
			notifyField:append(compile:docComment(notif.documentation))
		end
		notifyField:append(string.format("---@param params lsp.Notification.%s.params", methodTypeName))
		notifyField:append(string.format("notify[\"%s\"] = function(params) end", method))
		result.notify = notifyField
	end
	return result, routeContent
end
