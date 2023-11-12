local Buffer = require("compile.util.Buffer")

---@class compile
local compile = {
	enumeration = require("compile.Enumeration"),
	metamodel = require("compile.MetaModel"),
	notification = require("compile.Notification"),
	request = require("compile.Request"),
	structure = require("compile.Structure"),
	literal = require("compile.StructureLiteral"),
	property = require("compile.Property"),
	type = require("compile.Type"),
	typeAlias = require("compile.TypeAlias"),
}

---@param sep? string
---@return Buffer
function compile:buffer(sep)
	return Buffer(sep)
end

---@param buffer table
---@return Buffer
function compile:bufferOf(buffer)
	setmetatable(buffer, Buffer)
	return buffer
end



---@param str string
---@return fun(): string
local function lines(str)
	return string.gmatch(str, "[^\n]+")
end

---@param str string
---@return Buffer
function compile:docComment(str)
	local buffer = Buffer("\n")
	for line in lines(str) do
		buffer:append("---" .. line)
	end

	return buffer
end

return compile
