local maybeMove = require("lsp_def_gen.compile.util.maybeMove")

---Defines an unnamed structure of an object literal.
---@class lspm.StructureLiteral
---@field properties lspm.Property[]
---@field deprecated? string
---@field documentation? string
---@field since? string

---@param compile compile
---@param obj lspm.StructureLiteral
---@param name string
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj, name)
	local buffer = compile:buffer("\n")

	if obj.documentation then
		buffer:append(compile:docComment(obj.documentation))
	end

	buffer:append(name)

	local classBuffer = compile:buffer("\n")
	classBuffer:append("---@class " .. name)

	local classes = {}
	for _, property in ipairs(obj.properties) do
		local field, subClasses = compile:property(property, name)
		classBuffer:append(field)
		maybeMove(subClasses, classes)
	end

	table.insert(classes, classBuffer)

	return buffer, #classes > 0 and classes or nil
end
