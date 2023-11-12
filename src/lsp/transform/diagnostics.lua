local parse = require("server.parse")

local transformDiagnostic = require("lsp.transform.diagnostic")

local transformDiagnostics = {}

---@param text string
---@param state parse.state
---@return lsp.Diagnostic[]
function transformDiagnostics.fromParseStateToLSP(text, state)
	---@type lsp.Diagnostic[]
	local diagnostics = {}

	local errorResult = state.fail
	if errorResult then
		local info = parse.errors[errorResult.reason] or parse.errors["fail"]
		table.insert(diagnostics, transformDiagnostic.errorInfoToLSP(text, info, errorResult.position))
	end

	for _, entry in ipairs(state.errors) do
		table.insert(diagnostics, transformDiagnostic.parseErrorToLSP(text, entry))
	end
	return diagnostics
end

return transformDiagnostics
