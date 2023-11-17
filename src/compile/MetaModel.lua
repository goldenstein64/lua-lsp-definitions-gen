local move = require("lsp_def_gen.compile.util.move")

---@param t1 table?
---@param t2 table
local function maybeMove(t1, t2)
	if t1 then
		move(t1, t2)
	end
end

---@class lspm.MetaModel
---@field metaData lspm.MetaData
---@field structures lspm.Structure[]
---@field typeAliases lspm.TypeAlias[]
---@field notifications lspm.Notification[]
---@field requests lspm.Request[]
---@field enumerations lspm.Enumeration[]

---@class lspm.MetaData
---@field version string

---@param compile compile
---@param obj lspm.MetaModel
---@return Buffer definitions -- a buffer for the main lsp.d.lua file
---@return { [string]: Buffer } enums -- a key-value table of file names to buffers
return function(compile, obj)
	local buffer = compile:buffer("\n\n")

	buffer:append(compile:docComment(obj.metaData.version))
	buffer:append("---@alias lsp.DocumentUri string")
	buffer:append("---@alias lsp.URI string")

	-- Message base class
	buffer:append(compile:bufferOf({
		sep = "\n",
		"---A general message as defined by JSON-RPC. The language server protocol always",
		"---uses \"2.0\" as the `jsonrpc` version.",
		"---@class lsp.Message",
		"---@field jsonrpc \"2.0\"",
	}))

	-- Request base class
	buffer:append(compile:bufferOf({
		sep = "\n",
		"---A request message to describe a request between the client and the server.",
		"---Every processed request must send a response back to the sender of the",
		"---request.",
		"---@class lsp.Request : lsp.Message",
		"---The request id.",
		"---@field id integer | string",
		"---The method to be invoked.",
		"---@field method string",
		"---The method's params.",
		"---@field params table?",
	}))

	-- Response base class
	buffer:append(compile:bufferOf({
		sep = "\n",
		"---A Response Message sent as a result of a request. If a request doesn't",
		"---provide a result value the receiver of a request still needs to return a",
		"---response message to conform to the JSON-RPC specification. The result",
		"---property of the ResponseMessage should be set to `null` in this case to",
		"---signal a successful request.",
		"---@class lsp.Response : lsp.Message",
		"---The request id.",
		"---@field id integer | string | dkjson.null",
		"---The result of a request. This member is REQUIRED on success. This member MUST",
		"---NOT exist if there was an error invoking the method.",
		"---@field result? unknown",
		"---The error object in case a request fails.",
		"---@field error? lsp.ResponseError",
	}))

	-- Notification base class
	buffer:append(compile:bufferOf({
		sep = "\n",
		"---A notification message. A processed notification message must not send a",
		"---response back. They work like events.",
		"---@class lsp.Notification : lsp.Message",
		"---The method to be invoked.",
		"---@field method string",
		"---The notification's params.",
		"---@field params table?",
	}))

	-- ResponseError base class
	buffer:append(compile:bufferOf({
		sep = "\n",
		"---The error object in case a request fails.",
		"---@class lsp.ResponseError",
		"---A number indicating the error type that occurred.",
		"---@field code integer",
		"---A string providing a short description of the error.",
		"---@field message string",
		"---A primitive or structured value that contains additional information about",
	 	"---the error. Can be omitted.",
		"---@field data? string | number | boolean | table | dkjson.null"
	}))

	local classes = {}

	for _, structure in ipairs(obj.structures) do
		local compiled, subClasses = compile:structure(structure)
		buffer:append(compiled)
		maybeMove(subClasses, classes)
	end

	for _, typeAlias in ipairs(obj.typeAliases) do
		local compiled, subClasses = compile:typeAlias(typeAlias)
		buffer:append(compiled)
		maybeMove(subClasses, classes)
	end

	for _, notification in ipairs(obj.notifications) do
		local compiled, subClasses = compile:notification(notification)
		buffer:append(compiled)
		maybeMove(subClasses, classes)
	end

	for _, request in ipairs(obj.requests) do
		local compiled, subClasses = compile:request(request)
		buffer:append(compiled)
		maybeMove(subClasses, classes)
	end

	local enums = {}
	for _, enum in ipairs(obj.enumerations) do
		local compiled, subClasses = compile:enumeration(enum)
		enums[enum.name] = compiled
		maybeMove(subClasses, classes)
	end

	for _, class in ipairs(classes) do
		buffer:append(class)
	end

	return buffer, enums
end
