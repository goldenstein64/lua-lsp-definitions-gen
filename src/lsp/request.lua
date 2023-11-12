local ioLSP = require("lsp.io")

local request = {
	---@type { [integer]: thread }
	listeners = {},

	---@type integer
	id = 0
}

local requestMt = {}

---@param method string
---@param params table
---@return boolean, table
function requestMt:__call(method, params)
	local listener = coroutine.running()
	local id = self.id
	self.listeners[id] = listener
	self.id = id + 1
	if self.id > 2^53 then
		self.id = 0
	end

	---@type lsp.Request
	local req = {
		jsonrpc = "2.0",
		id = id,
		method = method,
		params = params,
	}

	ioLSP:write(req)

	return coroutine.yield()
end

return setmetatable(request, requestMt)
