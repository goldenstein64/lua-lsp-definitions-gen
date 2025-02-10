local json = require("cjson")
local compile_lsp = require("lsp-def-gen.compile.lsp")
local compile_lsp_lib = require("lsp-def-gen.compile.lsp-lib")
local lfs = require("lfs")

local ENUM_PATH_FORMAT = "out/enum/%s.lua"

local ROUTE_PATH_FORMAT = "out/routes/%s.lua"
local ROUTE_DIR_FORMAT = "out/routes/%s"

---@param path string
local function ensureDir(path)
	local workingPath = ""
	for folderName in path:gmatch("[^/]+") do
		if workingPath == "" then
			workingPath = folderName
		else
			workingPath = workingPath .. "/" .. folderName
		end
		local s, err = lfs.mkdir(workingPath)
		assert(s or err == "File exists", err)
	end
end

return function()
	local object do
		local data = assert(io.open("data/metaModel.json"))
		local content = data:read("a")

		---@type lspm.MetaModel
		object = assert(json.decode(content))
	end

	local definitions, enums = compile_lsp:metamodel(object)
	local libDefinitions, libRoutes = compile_lsp_lib:metamodel(object)

	ensureDir("out") do
		local definitionsFile = assert(io.open("out/lsp.d.lua", "w"))
		definitionsFile:write(tostring(definitions))
		definitionsFile:close()

		local libDefinitionsFile = assert(io.open("out/lsp-lib.d.lua", "w"))
		libDefinitionsFile:write(tostring(libDefinitions))
		libDefinitionsFile:close()
	end

	ensureDir("out/enum") do
		for name, buffer in pairs(enums) do
			local outFile = assert(io.open(ENUM_PATH_FORMAT:format(name), "w"))
			outFile:write(tostring(buffer))
			outFile:close()
		end
	end

	ensureDir("out/routes") do
		for method, content in pairs(libRoutes) do
			local moduleName = method:match("/([^/]+)$")
			if moduleName then
				local parentPath = assert(method:match("^(.+)/[^/]+$"), "parent path not found")
				ensureDir(ROUTE_DIR_FORMAT:format(parentPath))
			else
				moduleName = method
			end

			local routePath = ROUTE_PATH_FORMAT:format(method)
			local routeFile = assert(io.open(routePath, "w"))
			routeFile:write(content)
			routeFile:close()
		end
	end
end
