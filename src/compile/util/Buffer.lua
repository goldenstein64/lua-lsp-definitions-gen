---@class Buffer
---@field [integer] string | Buffer
---@field sep string
---@operator call(string?): Buffer
local Buffer = {}
Buffer.__index = Buffer

Buffer.sep = ""

---@param sep string
---@return Buffer
function Buffer.new(sep)
	local self = { sep = sep }
	setmetatable(self, Buffer)
	assert(type(self.sep) == "string", "sep is not a string")
	return self
end

---@param item string | Buffer
function Buffer:append(item)
	table.insert(self, item)
end

---@return string
function Buffer:__tostring()
	local stringified = {}
	for _, item in ipairs(self) do
		table.insert(stringified, tostring(item))
	end

	return table.concat(stringified, self.sep)
end

local classMt = {}

---@param sep string
function classMt:__call(sep)
	return Buffer.new(sep)
end

setmetatable(Buffer, classMt)

return Buffer
