local maybeMove = require("lsp-def-gen.compile.util.maybeMove")
local structureLiteral = require("lsp-def-gen.compile.StructureLiteral")

---Represents a base type like `string` or `DocumentUri`.
---@class lspm.BaseType
---@field kind "base"
---@field name lspm.BaseTypes

---@alias lspm.BaseTypes
---| "URI" | "DocumentUri"
---| "integer" | "uinteger" | "decimal"
---| "RegExp" | "string"
---| "boolean"
---| "null"

local compileType = {}

---@type { [lspm.BaseTypes]: string }
local baseTypeMap = {
	URI = "lsp.URI",
	DocumentUri = "lsp.DocumentUri",
	integer = "integer",
	uinteger = "integer",
	decimal = "number",
	RegExp = "lsp.RegExp",
	string = "string",
	boolean = "boolean",
	null = "dkjson.null",
}

---@param compile compile
---@param obj lspm.BaseType
---@return string
function compileType.base(compile, obj)
	return baseTypeMap[obj.name]
end

---Represents a reference to another type (e.g. `TextDocument`). This is either a `Structure`, a `Enumeration` or a `TypeAlias` in the same meta model.
---@class lspm.ReferenceType
---@field kind "reference"
---@field name string

---@param compile compile
---@param obj lspm.ReferenceType
---@return string
function compileType.reference(compile, obj)
	return "lsp." .. obj.name
end

---Represents an array type (e.g. `TextDocument[]`).
---@class lspm.ArrayType
---@field kind "array"
---@field element lspm.Type

---@param compile compile
---@param obj lspm.ArrayType
---@param name string
---@return string
---@return Buffer[]? classes
function compileType.array(compile, obj, name)
	local field, classes = compile:type(obj.element, name)
	return tostring(field) .. "[]", classes
end

---Represents a JSON object map (e.g. `interface Map<K extends string | integer, V> { [key: K] => V; }`).
---@class lspm.MapType
---@field kind "map"
---@field key lspm.MapKeyType | lspm.ReferenceType
---@field value lspm.Type

---@param compile compile
---@param obj lspm.MapType
---@param name string
---@return string
---@return Buffer[]? classes
function compileType.map(compile, obj, name)
	local keyField, keyClasses = compile:type(obj.key, name .. ".key")
	local valueField, valueClasses = compile:type(obj.value, name .. ".value")
	local classes = {}
	maybeMove(keyClasses, classes)
	maybeMove(valueClasses, classes)

	return string.format("{ [%s]: %s }", keyField, valueField), classes
end

---@class lspm.MapKeyType
---@field kind "base"
---@field name "URI" | "DocumentUri" | "string" | "integer"

---Represents an `and` type (e.g. TextDocumentParams & WorkDoneProgressParams`).
---@class lspm.AndType
---@field kind "and"
---@field items lspm.Type[]

---@param compile compile
---@param obj lspm.AndType
---@param name string
---@return string
---@return Buffer[]? classes
function compileType._and(compile, obj, name)
	local bases = {} ---@type string[]
	local classes = {} ---@type Buffer[]
	for i, item in ipairs(obj.items) do
		local field, subClasses = compile:type(item, string.format("%s.%d", name, i))
		table.insert(bases, tostring(field))
		maybeMove(subClasses, classes)
	end

	local classBuffer = compile:buffer("\n")
	local classLine = string.format("@class %s : %s", name, table.concat(bases, ", "))
	classBuffer:append(compile:docComment(classLine))

	table.insert(classes, classBuffer)

	return name, classes
end
compileType["and"] = compileType._and

---Represents an `or` type (e.g. `Location | LocationLink`).
---@class lspm.OrType
---@field kind "or"
---@field items lspm.Type[]

---@param compile compile
---@param obj lspm.OrType
---@param name string
---@return string
---@return Buffer[]? classes
function compileType._or(compile, obj, name)
	local stringified = {}
	local classes = {}
	for i, item in ipairs(obj.items) do
		local field, subClasses = compile:type(item, string.format("%s.%d", name, i))
		table.insert(stringified, tostring(field))
		maybeMove(subClasses, classes)
	end

	return table.concat(stringified, " | "), #classes > 0 and classes or nil
end
compileType["or"] = compileType._or

---Represents a `tuple` type (e.g. `[integer, integer]`).
---@class lspm.TupleType
---@field kind "tuple"
---@field items lspm.Type[]

---@param compile compile
---@param obj lspm.TupleType
---@param name string
---@return string
---@return Buffer[]? classes
function compileType.tuple(compile, obj, name)
	local buffer = compile:buffer(" ")
	buffer:append("{")
	local classes = {}
	for i, item in ipairs(obj.items) do
		local type, subClasses = compile:type(item, string.format("%s.%d", name, i))
		buffer:append(string.format("[%d]: %s,", i, tostring(type)))
		maybeMove(subClasses, classes)
	end
	buffer:append("}")

	return tostring(buffer), classes
end

---Represents a literal structure (e.g. `property: { start: uinteger; end: uinteger; }`).
---@class lspm.StructureLiteralType
---@field kind "literal"
---@field value lspm.StructureLiteral

---@param compile compile
---@param obj lspm.StructureLiteralType
---@param name string
function compileType.literal(compile, obj, name)
	return structureLiteral(compile, obj.value, name)
end

---Represents a string literal type (e.g. `kind: 'rename'`).
---@class lspm.StringLiteralType
---@field kind "stringLiteral"
---@field value string

---@param compile compile
---@param obj lspm.StringLiteralType
---@return string
---@return Buffer[]? classes
function compileType.stringLiteral(compile, obj)
	return string.format("%q", obj.value)
end

---Represents an integer literal type (e.g. `kind: 1`).
---@class lspm.IntegerLiteralType
---@field kind "integerLiteral"
---@field value integer

---@param compile compile
---@param obj lspm.IntegerLiteralType
---@return string
---@return Buffer[]? classes
function compileType.integerLiteral(compile, obj)
	return tostring(obj.value)
end

---Represents a boolean literal type (e.g. `kind: true`).
---@class lspm.BooleanLiteralType
---@field kind "booleanLiteral"
---@field value boolean

---@param compile compile
---@param obj lspm.BooleanLiteralType
---@return string
---@return Buffer[]? classes
function compileType.booleanLiteral(compile, obj)
	return tostring(obj.value)
end

---@alias lspm.Type
---| lspm.BaseType
---| lspm.MapKeyType
---| lspm.ReferenceType
---| lspm.ArrayType
---| lspm.MapType
---| lspm.AndType
---| lspm.OrType
---| lspm.TupleType
---| lspm.StructureLiteralType
---| lspm.StringLiteralType
---| lspm.IntegerLiteralType
---| lspm.BooleanLiteralType

---@param compile compile
---@param obj lspm.Type
---@param name string
---@return string
---@return Buffer[]? classes
return function(compile, obj, name)
	return compileType[obj.kind](compile, obj, name)
end
