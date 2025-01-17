
-- "loadfile"
local function dofileArg(path)

	local loaded = false
	local getfile = function()

		if loaded then
			return
		else
			local file,err = io.open(path)
			if not file then
				error("error loading file "..path..": "..err)
			end
			local ret = file:read("*a")
			file:close()

			ret = string.gsub(ret, "%.%.%.%s*%)", "...) local arg = {n=select('#', ...), ...};")

			loaded = true
			return ret
		end
	end

	local f = load(getfile, path)
	if not f then
	
		error("error loading file "..path)
	end
	return f()
end




-- string.gsub
--[[
local ogsub = string.gsub
local function compgsub(a,b,c,d)
  if type(c) == "function" then
    local oc = c
    c = function (...) return oc(...) or '' end
  end
  return ogsub(a,b,c,d)
end
string.repl = ogsub
--]]

--string.gsub = compgsub




