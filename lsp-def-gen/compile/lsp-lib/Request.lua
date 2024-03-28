local REQUEST_PATH_FORMAT = "out/routes/%s.lua"
local REQUEST_DIR_FORMAT = "out/routes/%s"

local REQUEST_READ_FORMAT = [[
---@param params lsp.Request.%s.params
---@return lsp.Response.%s.result
return function(params) end
]]

---@param request lspm.Request
---@return string content
local function generateRouteContent(request)
	local method = request.method
	local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
	return REQUEST_READ_FORMAT:format(methodTypeName, methodTypeName, method)
end

---@param compile compile_lsp_lib
---@param request lspm.Request
---@return { response: Buffer?, request?: Buffer? }
---@return string? routeContent
return function(compile, request)
	local dir = request.messageDirection
	local method = request.method
	local methodTypeName = method:gsub("%$", "_"):gsub("/", "-")
	-- local methodName = method:gsub("%$/", ""):gsub("/", "_")

	if dir == "clientToServer" then
		local responseField = compile:buffer("\n")
		if request.documentation then
			responseField:append(compile:docComment(request.documentation))
		end
		responseField:append(string.format(
			"---@type fun(params: lsp.Request.%s.params): lsp.Response.%s.result",
			methodTypeName, methodTypeName
		))
		responseField:append(string.format("response[\"%s\"] = nil", method))
		return { response = responseField }, generateRouteContent(request)
	elseif dir == "serverToClient" then
		local requestField = compile:buffer("\n")
		if request.documentation then
			requestField:append(compile:docComment(request.documentation))
		end
		requestField:append(string.format("---@param params lsp.Request.%s.params", methodTypeName))
		requestField:append(string.format("---@return lsp.Response.%s.result? result", methodTypeName))
		requestField:append(string.format("---@return lsp.Response.%s.error? error", methodTypeName))
		requestField:append(string.format("request[\"%s\"] = function(params) end", method))
		return { request = requestField }
	else
		error("unhandled direction: " .. tostring(dir))
	end
end
