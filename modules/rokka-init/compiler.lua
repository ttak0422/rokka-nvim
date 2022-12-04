local function compile(target_filename, out_filename)
	local chunk = assert(loadfile(target_filename))
	local file = assert(io.open(out_filename, "w+b"))
	file:write(string.dump(chunk))
	file:close()
end

compile(arg[1], arg[2])
