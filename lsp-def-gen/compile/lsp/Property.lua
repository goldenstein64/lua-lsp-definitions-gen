---Represents an object property.
---@class lspm.Property
---@field name string
---@field type lspm.Type
---@field documentation? string
---Defaults to `false`
---@field optional? boolean

---@param compile compile_lsp
---@param obj lspm.Property
---@param parentName string
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj, parentName)
	local buffer = compile:buffer("\n")

	if obj.documentation then
		buffer:append(compile:docComment(obj.documentation))
	end

	local fieldBuffer = compile:buffer()
	fieldBuffer:append("---@field ")
	fieldBuffer:append(obj.name)
	if obj.optional then
		fieldBuffer:append("? ")
	else
		fieldBuffer:append(" ")
	end

	local pathName = table.concat({parentName, obj.name}, ".")
	local fieldType, classes = compile:type(obj.type, pathName)
	fieldBuffer:append(fieldType)
	buffer:append(fieldBuffer)

	return buffer, classes
end
