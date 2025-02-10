---@param compile compile_lsp_lib
---@param obj lspm.MetaModel
---@return Buffer definitions
---@return { [string]: string } routes
return function(compile, obj)
	local buffer = compile:buffer('\n\n')

	buffer:append("---@meta")

	local responseBuffer = compile:buffer('\n\n')
	responseBuffer:append("---@class lsp-lib.Response\nlocal response = {}")
	local requestBuffer = compile:buffer('\n\n')
	requestBuffer:append("---@class lsp-lib.Request\nlocal request = {}")
	local notifyBuffer = compile:buffer('\n\n')
	notifyBuffer:append("---@class lsp-lib.Notify\nlocal notify = {}")

	---@type { [string]: string }
	local routes = {}

	for _, request in ipairs(obj.requests) do
		local result, routeContent = compile:request(request)
		if result.response then
			responseBuffer:append(result.response)
		else
			requestBuffer:append(result.request)
		end

		if routeContent then
			routes[request.method] = routeContent
		end
	end

	for _, notif in ipairs(obj.notifications) do
		local result, routeContent = compile:notification(notif)

		if result.response then
			responseBuffer:append(result.response)
		end

		if result.notify then
			notifyBuffer:append(result.notify)
		end

		if routeContent then
			routes[notif.method] = routeContent
		end
	end

	buffer:append(responseBuffer)
	buffer:append(requestBuffer)
	buffer:append(notifyBuffer)
	return buffer, routes
end
