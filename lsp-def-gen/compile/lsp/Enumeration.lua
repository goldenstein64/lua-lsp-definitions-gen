---Defines an enumeration.
---@class lspm.Enumeration
---@field name string
---@field type lspm.EnumerationType
---@field values lspm.EnumerationEntry[]
---Whether the enumeration is deprecated or not. If deprecated the property contains the deprecation message.
---@field deprecated? string
---@field documentation? string
---Whether this is a proposed enumeration. If omitted, the enumeration is final.
---@field proposed? boolean
---@field since? string
---Whether the enumeration supports custom values (e.g. values which are not part of the set defined in `values`). If omitted no custom values are supported.
---@field supportsCustomValues? boolean

---@class lspm.EnumerationType
---@field kind "base"
---@field name "string" | "integer" | "uinteger"

---Defines an enumeration entry.
---@class lspm.EnumerationEntry
---@field name string
---@field value string | number
---@field documentation? string

local isKeyword = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}

local ENUM_FORMAT = "---@enum lsp.%s"
local TABLE_HEAD_FORMAT = "local %s = {"
local TABLE_STRING_ENTRY_FORMAT = "\t%s = %q,"
local TABLE_INTEGER_ENTRY_FORMAT = "\t%s = %d,"
local TABLE_FOOT_FORMAT = "}"
local RETURN_FORMAT = "return %s"

---@param compile compile_lsp
---@param obj lspm.Enumeration
---@return Buffer
---@return Buffer[]? classes
return function(compile, obj)
	local buffer = compile:buffer("\n")

	if obj.documentation then
		buffer:append(compile:docComment(obj.documentation))
	end
	buffer:append(ENUM_FORMAT:format(obj.name))
	buffer:append(TABLE_HEAD_FORMAT:format(obj.name))

	local entryFormat
	if obj.type.name == "string" then
		entryFormat = TABLE_STRING_ENTRY_FORMAT
	else
		entryFormat = TABLE_INTEGER_ENTRY_FORMAT
	end

	local entriesBuffer = compile:buffer("\n\n")
	for _, entry in ipairs(obj.values) do
		local entryBuffer = compile:buffer("\n")
		if entry.documentation then
			entryBuffer:append(compile:docComment(entry.documentation, 1))
		end

		local entryName = entry.name
		if isKeyword[entry.name] then
			entryName = string.format("_%s", entryName)
		end

		entryBuffer:append(entryFormat:format(entryName, entry.value))

		entriesBuffer:append(entryBuffer)
	end
	buffer:append(entriesBuffer)

	buffer:append(TABLE_FOOT_FORMAT)
	buffer:append("")
	buffer:append(RETURN_FORMAT:format(obj.name))

	return buffer
end
