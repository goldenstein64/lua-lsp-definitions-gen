local Buffer = require("lsp-def-gen.compile.util.Buffer")

local INDENT_CHAR = "\t"

---@class compile
local compile = {
	enumeration = require("lsp-def-gen.compile.Enumeration"),
	metamodel = require("lsp-def-gen.compile.MetaModel"),
	notification = require("lsp-def-gen.compile.Notification"),
	request = require("lsp-def-gen.compile.Request"),
	structure = require("lsp-def-gen.compile.Structure"),
	literal = require("lsp-def-gen.compile.StructureLiteral"),
	property = require("lsp-def-gen.compile.Property"),
	type = require("lsp-def-gen.compile.Type"),
	typeAlias = require("lsp-def-gen.compile.TypeAlias"),
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
---@param indent? integer
---@return Buffer
function compile:docComment(str, indent)
	indent = indent or 0
	local buffer = Buffer("\n")
	for line in lines(str) do
		buffer:append(INDENT_CHAR:rep(indent) .. "---" .. line)
	end

	return buffer
end

return compile
