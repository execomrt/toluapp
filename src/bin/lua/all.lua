-- tolua++ -o LuaNotification.inl LuaNotification.pkg
-- _extra_parameters = {}
 --flags = {}
 --flags.f = "D:\\Trash\\rlx32\\src\\libLithium\\LuaAWS.pkg"
-- arg = {} 

TOLUA_VERSION = "1.0.99-C++17"
dofile("compat-5.1.lua")
dofile("compat.lua")
dofile("basic.lua")
dofile("feature.lua")
dofile("verbatim.lua")
dofile("code.lua")
dofile("typedef.lua")
dofile("container.lua")
dofile("package.lua")
dofile("module.lua")
dofile("namespace.lua")
dofile("define.lua")
dofile("enumerate.lua")
dofile("declaration.lua")
dofile("variable.lua")
dofile("array.lua")
dofile("function.lua")
dofile("operator.lua")
dofile("template_class.lua")
dofile("class.lua")
dofile("clean.lua")
--dofile("custom.lua")
dofile("doit.lua")

local err,msg = xpcall(doit, debug.traceback)
if not err then
print("**** msg is "..tostring(msg))
-- local _,_,label,msg = strfind(msg,"(.-:.-:%s*)(.*)")
 --tolua_error(msg,label)
end


