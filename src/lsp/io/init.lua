---@alias lsp.LSPMessage lsp.Request | lsp.Response | lsp.Notification

---@class lsp*.io.provider
---@field read fun(self: lsp*.io.provider): (lsp.LSPMessage)
---@field write fun(self: lsp*.io.provider, data: lsp.LSPMessage)
---@field open fun(self: lsp*.io.provider, args: any)
---@field close fun(self: lsp*.io.provider)

---@class lsp*.io
---@field provider lsp*.io.provider
---@field readCallback? fun(data: lsp.LSPMessage)
---@field writeCallback? fun(data: lsp.LSPMessage)
local ioLSP = {}

---@return lsp.LSPMessage
function ioLSP:read()
	local data = self.provider:read()
	if self.readCallback then
		self.readCallback(data)
	end
	return data
end

local NON_TABLE_ERROR = "sent a non-table (%s) %s"

---@param data lsp.LSPMessage
function ioLSP:write(data)
	if type(data) ~= "table" then
		error(NON_TABLE_ERROR:format(type(data), tostring(data)))
	end

	if data.id and not (data.result and not data.error or not data.result and data.error) then
		error("malformed response")
	elseif not data.id and not (data.params and data.method) then
		error("malformed notification")
	end

	if self.writeCallback then
		self.writeCallback(data)
	end
	self.provider:write(data)
end

return ioLSP
