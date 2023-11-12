local transformRange = require("lsp.transform.range")

local transformDiagnostic = {}

---@param text string
---@param entry parse.error
---@return lsp.Diagnostic
function transformDiagnostic.parseErrorToLSP(text, entry)
	---@type lsp.Diagnostic
	return {
		message = entry.message,
		code = entry.code,
		range = transformRange.toLSP(text, entry.position[1], entry.position[2]),
	}
end

---@param text string
---@param info parse.error_info
---@param position integer
---@return lsp.Diagnostic
function transformDiagnostic.errorInfoToLSP(text, info, position)
	---@type lsp.Diagnostic
	return {
		message = info.message,
		code = info.code,
		range = transformRange.toLSP(text, position)
	}
end

return transformDiagnostic
