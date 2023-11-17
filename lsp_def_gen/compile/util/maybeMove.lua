local move = require("lsp_def_gen.compile.util.move")

---@param t1 table?
---@param t2 table
return function(t1, t2)
	if t1 then
		move(t1, t2)
	end
end
