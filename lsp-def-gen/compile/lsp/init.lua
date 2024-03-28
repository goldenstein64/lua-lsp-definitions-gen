
local compile = require("lsp-def-gen.compile")

---@class compile_lsp : compile
local compile_lsp = {
	enumeration = require("lsp-def-gen.compile.lsp.Enumeration"),
	metamodel = require("lsp-def-gen.compile.lsp.MetaModel"),
	notification = require("lsp-def-gen.compile.lsp.Notification"),
	request = require("lsp-def-gen.compile.lsp.Request"),
	structure = require("lsp-def-gen.compile.lsp.Structure"),
	literal = require("lsp-def-gen.compile.lsp.StructureLiteral"),
	property = require("lsp-def-gen.compile.lsp.Property"),
	type = require("lsp-def-gen.compile.lsp.Type"),
	typeAlias = require("lsp-def-gen.compile.lsp.TypeAlias"),
}

setmetatable(compile_lsp, { __index = compile })

return compile_lsp
