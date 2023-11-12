---Defines a type alias. (e.g. `type Definition = Location | LocationLink`)
---@class lspm.TypeAlias
---@field name string
---@field type lspm.Type
---@field documentation? string

local NAME_FORMAT = "lsp.%s"
local SUB_NAME_FORMAT = "lsp.%s.alias"

---@param compile compile
---@param obj lspm.TypeAlias
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj)
	local buffer = compile:buffer("\n")

	if obj.documentation then
		buffer:append(compile:docComment(obj.documentation))
	end

	local aliasBuffer = compile:buffer(" ")
	aliasBuffer:append("---@alias")
	aliasBuffer:append(NAME_FORMAT:format(obj.name))

	local field, classes = compile:type(obj.type, SUB_NAME_FORMAT:format(obj.name))
	aliasBuffer:append(field)
	buffer:append(aliasBuffer)

	return buffer, classes
end
