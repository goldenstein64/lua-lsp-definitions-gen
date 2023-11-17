---@param t1 table
---@param t2 table
return function(t1, t2)
	table.move(t1, 1, #t1, #t2 + 1, t2)
end
