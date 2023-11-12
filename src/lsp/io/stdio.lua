---@class lsp*.io.provider.stdio : lsp*.io.provider
local ioStd = {}

function ioStd:open(args) end
function ioStd:close() end

---@param bytes integer
---@return string
function ioStd:read(bytes)
	return io.read(bytes)
end

---@param data string
function ioStd:write(data)
	data = data:gsub("\r", "")
	io.write(data)
	io.stdout:flush()
end

return ioStd
