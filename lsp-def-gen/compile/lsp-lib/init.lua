local Buffer = require("lsp-def-gen.compile.util.Buffer")
local compile = require("lsp-def-gen.compile")

---@class compile_lsp_lib : compile
local compile_lsp_lib = {
	metamodel = require("lsp-def-gen.compile.lsp-lib.MetaModel"),
	request = require("lsp-def-gen.compile.lsp-lib.Request"),
	notification = require("lsp-def-gen.compile.lsp-lib.Notification"),
}

setmetatable(compile_lsp_lib, { __index = compile })

return compile_lsp_lib
