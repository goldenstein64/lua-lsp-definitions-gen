local move = require("lsp_def_gen.compile.util.move")

---@param t1 table?
---@param t2 table
local function maybeMove(t1, t2)
	if t1 then
		move(t1, t2)
	end
end

---Defines the structure of an object literal.
---@class lspm.Structure
---@field name string
---@field properties lspm.Property[]
---@field deprecated? string
---@field documentation? string
---Structures extended from. This structures form a polymorphic type hierarchy.
---@field extends? lspm.Type[]
---Structures to mix in. The properties of these structures are `copied` into
---this structure. Mixins don't form a polymorphic type hierarchy in LSP.
---@field mixins? lspm.Type[]
---@field since? string

---@param compile compile
---@param obj lspm.Structure
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj)
	local buffer = compile:buffer("\n")

	local structName = "lsp." .. obj.name

	if obj.documentation then
		buffer:append(compile:docComment(obj.documentation))
	end

	local inherits = {}
	local classes = {}
	if obj.extends then
		for _, item in ipairs(obj.extends) do
			local field, subClasses = compile:type(item, structName)
			table.insert(inherits, field)
			maybeMove(subClasses, classes)
		end
	end

	if obj.mixins then
		for _, item in ipairs(obj.mixins) do
			local field, subClasses = compile:type(item, structName)
			table.insert(inherits, field)
			maybeMove(subClasses, classes)
		end
	end

	local classStr ---@type string
	if #inherits > 0 then
		classStr = string.format("---@class %s : %s", structName, table.concat(inherits, ", "))
	else
		classStr = "---@class " .. structName
	end
	buffer:append(classStr)

	for _, property in ipairs(obj.properties) do
		local field, subClasses = compile:property(property, structName)
		buffer:append(field)
		maybeMove(subClasses, classes)
	end

	return buffer, #classes > 0 and classes or nil
end
