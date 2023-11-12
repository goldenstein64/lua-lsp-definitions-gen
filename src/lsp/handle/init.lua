local ioLSP = require("lsp.io")

local notify = require("lsp.notify")
local register = require("lsp.register")
local request = require("lsp.request")

local errors = require("lsp.handle.errors")
local inspect = require("inspect")

local handle = {
	---@type { [thread]: lsp.Request | lsp.Notification }
	threadMap = {},
}

---@return lsp.LSPMessage?
local function getRequest()
	local s, request = pcall(ioLSP.read, ioLSP)
	if not s then
		ioLSP:write(errors.ParseError(request --[[@as string?]]))
	end

	return s and request or nil
end

local ERR_UNKNOWN_PROTOCOL = "invoked an unknown protocol '%s'"

---@param req lsp.Request | lsp.Notification
---@return nil | fun(params: any): any
local function getRoute(req)
	local route = register[req.method]
	local isRequired = req.method:sub(1, 1) ~= "$"
	if not route then
		local isRequest = req.id ~= nil
		if isRequest then
			if isRequired then
				ioLSP:write(errors.MethodNotFound(req.id, req.method))
				notify.window_logMessage(ERR_UNKNOWN_PROTOCOL:format(req.method), "error")
			end
		else
			notify.window_logMessage(ERR_UNKNOWN_PROTOCOL:format(req.method), "error")
		end

		return nil
	end

	return route
end

---@class lsp*.RouteError
---@field result? lsp.ResponseError
---@field msg string

---@param result lsp.ResponseError | string
---@return lsp*.RouteError
local function handleRouteError(result)
	if type(result) == "table" and result.message and result.code then -- graceful error, leave it alone
		return { result = result, msg = debug.traceback(result.message) }
	elseif type(result) == "string" then
		return { msg = debug.traceback(result) }
	else
		return { msg = debug.traceback("non-string error: " .. inspect(result)) }
	end
end

local NO_RESPONSE_ERROR = "request '%s' was not responded to"

---@param req lsp.Request
---@param result unknown
---@return lsp.Response
local function handleRequestResult(req, result)
	if result ~= nil then
		-- request handlers should always return a result on success
		return { id = req.id, result = result }
	else
		local msg = NO_RESPONSE_ERROR:format(req.method)
		notify.window_logMessage(msg, "error")
		return errors.general(req.id, msg)
	end
end

---@param req lsp.Request
---@param err lsp*.RouteError
---@return lsp.Response
local function handleRequestError(req, err)
	notify.window_logMessage("request error: " .. tostring(err.msg), "error")
	if err.result then -- graceful error
		return { id = req.id, error = err.result }
	else -- messy error
		return errors.general(req.id, err.msg)
	end
end

---@param req lsp.Request
---@param ok boolean
---@param result unknown
local function handleRequestRoute(req, ok, result)
	local response ---@type lsp.Response
	if ok then -- successful request
		response = handleRequestResult(req, result)
	else
		---@cast result lsp*.RouteError
		response = handleRequestError(req, result)
	end

	ioLSP:write(response)
end

local RESPONSE_ERROR = "notification '%s' was responded to"

---@param notif lsp.Notification
---@param ok boolean
---@param result unknown
local function handleNotificationRoute(notif, ok, result)
	if ok and result ~= nil then
		notify.window_logMessage(RESPONSE_ERROR:format(notif.method), "error")
	elseif not ok then
		---@cast result lsp*.RouteError
		notify.window_logMessage(result.msg, "error")
	end
end

local NO_REQUEST_STORED_ERROR = "request not stored for thread '%s'"

---@param thread thread
---@param ... any
local function executeThread(thread, ...)
	local ok, result = coroutine.resume(thread, ...)
	if coroutine.status(thread) == "suspended" then
		-- waiting for a request to complete
		-- all the book-keeping should've been finished before this, so just return
		return
	end

	if not ok then
		result = handleRouteError(result)
	end

	local req = handle.threadMap[thread]
	if not req then
		error(NO_REQUEST_STORED_ERROR:format(thread))
	end
	handle.threadMap[thread] = nil
	if req.id then
		---@cast req lsp.Request
		handleRequestRoute(req, ok, result)
	else
		---@cast req lsp.Notification
		handleNotificationRoute(req, ok, result)
	end
end

---@param route fun(params: any): any
---@param req lsp.Request | lsp.Notification
local function handleRoute(route, req)
	local thread = coroutine.create(route)
	handle.threadMap[thread] = req
	executeThread(thread, req.params)
end

---@param res lsp.Response
local function handleResponse(res)
	local thread = request.listeners[res.id] ---@type thread
	if not thread then
		error(string.format("no listener for response id '%s'", tostring(res.id)))
	end

	executeThread(thread, res.result and true or false, res.result or res.error)
end

function handle.initialize()
	local req = getRequest()
	if not req then return end

	if not req.method then
		---@cast req lsp.Response
		handleResponse(req)
		return
	end
	---@cast req lsp.Request | lsp.Notification

	if req.method ~= "initialize" and req.method ~= "exit" then
		ioLSP:write(errors.ServerNotInitialized(req.id))
		return
	end

	local route = getRoute(req)
	if not route then return end

	handleRoute(route, req)
end

function handle.default()
	local req = getRequest()
	if not req then return end

	if not req.method then
		---@cast req lsp.Response
		handleResponse(req)
		return
	end
	---@cast req lsp.Request | lsp.Notification

	local route = getRoute(req)
	if not route then return end

	handleRoute(route, req)
end

function handle.shutdown()
	local req = getRequest()
	if not req then return end

	if not req.method then
		---@cast req lsp.Response
		handleResponse(req)
		return
	end
	---@cast req lsp.Request | lsp.Notification

	if req.method ~= "exit" then
		ioLSP:write(errors.InvalidRequest(req.id, req.method))
		return
	end

	local route = getRoute(req)
	if not route then return end

	handleRoute(route, req)
end

return handle
