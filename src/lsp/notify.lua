local ioLSP = require("lsp.io")

local notify = {
	id = 0,
}

local notifyMt = {}

---@param method string
---@param params table
function notifyMt:__call(method, params)
	ioLSP:write({
		jsonrpc = "2.0",
		method = method,
		params = params
	})
end

return setmetatable(notify, notifyMt)
