local json = require("dkjson")
local socket = require("socket")

local RESPONSE_FMT = "Content-Length: %d\r\n\r\n%s"

---@class lsp*.io.provider.socket : lsp*.io.provider
local ioSocket = {
	requestQueue = {},

	---@type socket.tcp.client
	connection = nil,
}

function ioSocket:open(args)
	local connection = assert(socket.connect("127.0.0.1", args.socket))
	---@cast connection socket.tcp.client

	self.connection = connection
end

function ioSocket:close()
	if self.connection then
		self.connection:close()
		self.connection = nil
	end
end

---@param self lsp*.io.provider.socket
local function readHeaderLine(self)
	local buffer = {}
	while true do
		local byte = assert(self.connection:receive(1))
		table.insert(buffer, byte)
		if byte == "\r" then
			byte = assert(self.connection:receive(1))
			table.insert(buffer, byte)
			if byte == "\n" then
				return table.concat(buffer)
			end
		end
	end
end

---@return lsp.Request | lsp.Notification
function ioSocket:read()
	if #self.requestQueue > 0 then
		return table.remove(self.requestQueue, 1)
	end

	local headers = {}
	local header = readHeaderLine(self)
	while not header or not header:match("^[\r\n]+$") do
		if not header then
			goto continue
		end
		local key, value = header:match("^([%w%-]+): ([^\r\n]+)[\r\n]*$")
		assert(key, "unable to parse header")
		headers[string.lower(key)] = value
		header = readHeaderLine(self)
		::continue::
	end

	local len = tonumber(headers["content-length"])
	assert(len, "could not find length")
	local contentType = headers["content-type"] ---@type string?
	assert(
		not contentType or (
			contentType:find("^application/vscode%-jsonrpc")
			and contentType:find("charset=utf%-8$")
		),
		"cannot handle content types other than 'application/vscode-jsonrpc; charset=utf-8'"
	)

	local content = assert(self.connection:receive(len))

	local object, pos, err = json.decode(content, 1, json.null)
	assert(type(object) == "table", err)
	assert(pos > len, "Parse error")

	local mt = getmetatable(object)
	local jsonType = mt and mt.__jsontype
	if jsonType == "array" then
		---@diagnostic disable-next-line:deprecated
		table.move(object, 2, #object, #self.requestQueue + 1, self.requestQueue)
		return object[1]
	end

	return object
end

---@param data lsp.Response | lsp.Notification
function ioSocket:write(data)
	data.jsonrpc = "2.0"
	local content = json.encode(data)

	local contentLength = string.len(content)
	local response = RESPONSE_FMT:format(contentLength, content)

	self.connection:send(response)
end

return ioSocket
