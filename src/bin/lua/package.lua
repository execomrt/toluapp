-- tolua: package class
-- Written by Waldemar Celes
-- TeCGraf/PUC-Rio
-- Jul 1998
-- $Id: $

-- This code is free software; you can redistribute it and/or modify it.
-- The software provided hereunder is on an "as is" basis, and
-- the author has no obligation to provide maintenance, support, updates,
-- enhancements, or modifications.



-- Package class
-- Represents the whole package being bound.
-- The following fields are stored:
--    {i} = list of objects in the package.
classPackage = {
 classtype = 'package'
}
classPackage.__index = classPackage
setmetatable(classPackage,classContainer)

-- Print method
function classPackage:print ()
 print("Package: "..self.name)
 local i=1
 while self[i] do
  self[i]:print("","")
  i = i+1
 end
end

function classPackage:preprocess ()

 -- avoid preprocessing embedded Lua code
 local L = {}
 self.code = gsub(self.code,"\n%s*%$%[","\1") -- deal with embedded lua code
 self.code = gsub(self.code,"\n%s*%$%]","\2")
 self.code = gsub(self.code,"(%b\1\2)",       function (c)
                                               tinsert(L,c)
                                               return "\n#["..getn(L).."]#"
                                              end)
 -- avoid preprocessing embedded C code
 local C = {}
 self.code = gsub(self.code,"\n%s*%$%<","\3") -- deal with embedded C code
 self.code = gsub(self.code,"\n%s*%$%>","\4")
 self.code = gsub(self.code,"(%b\3\4)",       function (c)
                                               tinsert(C,c)
                                               return "\n#<"..getn(C)..">#"
                                              end)
 -- avoid preprocessing embedded C code
 self.code = gsub(self.code,"\n%s*%$%{","\5") -- deal with embedded C code
 self.code = gsub(self.code,"\n%s*%$%}","\6")
 self.code = gsub(self.code,"(%b\5\6)",       function (c)
                                               tinsert(C,c)
                                               return "\n#<"..getn(C)..">#"
                                              end)

 -- avoid preprocessing verbatim lines
 -- try preserve order
 local verbatimLineRE = "\n%s*%$([^%[%]][^\n]*)"
 local verbatimBlockRE = "<verbatim>(.-)</verbatim>"
 local findFrom, findTo
 local verbatimTbl = {}
 findTo = 0
 repeat
	findFrom, findTo = self.code:find(verbatimLineRE, findTo+1)
	if findFrom then
		table.insert(verbatimTbl, {findFrom, 'L'})
	end
 until not findFrom 

 findTo = 0
 repeat
	findFrom, findTo = self.code:find(verbatimBlockRE, findTo+1)
	if findFrom then
		table.insert(verbatimTbl, {findFrom, 'B'})
	end
 until not findFrom 
 
 table.sort(verbatimTbl, function(a,b) return a[1] < b[1] end)
 
 for k,v in pairs(verbatimTbl) do
	local useRE
	if v[2] == 'L' then
		useRE = verbatimLineRE
	else
		useRE = verbatimBlockRE
	end
	self.code = gsub(self.code,useRE,function (v)
			Verbatim(v .. '\n')
			haveFound = true
			return "\n"
		end)
 end
 
 --self.code = gsub(self.code,"\n%s*#[^d][^\n]*\n", "\n\n") -- eliminate preprocessor directives that don't start with 'd'
 self.code = gsub(self.code,"\n[ \t]*#[ \t]*[^d%<%[]", "\n//") -- eliminate preprocessor directives that don't start with 'd'

 -- perform global substitution

 self.code = gsub(self.code,"(//[^\n]*)","")     -- eliminate C++ comments
 self.code = gsub(self.code,"/%*","\1")
 self.code = gsub(self.code,"%*/","\2")
 self.code = gsub(self.code,"%b\1\2","")
 self.code = gsub(self.code,"\1","/%*")
 self.code = gsub(self.code,"\2","%*/")
 self.code = gsub(self.code,"%s*@%s*","@") -- eliminate spaces beside @
 self.code = gsub(self.code,"%s?inline(%s)","%1") -- eliminate 'inline' keyword
 --self.code = gsub(self.code,"%s?extern(%s)","%1") -- eliminate 'extern' keyword
 --self.code = gsub(self.code,"%s?virtual(%s)","%1") -- eliminate 'virtual' keyword
 --self.code = gsub(self.code,"public:","") -- eliminate 'public:' keyword
 self.code = gsub(self.code,"([^%w_])void%s*%*","%1_userdata ") -- substitute 'void*'
 self.code = gsub(self.code,"([^%w_])void%s*%*","%1_userdata ") -- substitute 'void*'
 self.code = gsub(self.code,"([^%w_])char%s*%*","%1_cstring ")  -- substitute 'char*'
 self.code = gsub(self.code,"([^%w_])lua_State%s*%*","%1_lstate ")  -- substitute 'lua_State*'

 -- restore embedded Lua code
 self.code = gsub(self.code,"%#%[(%d+)%]%#",function (n)
                                              return L[tonumber(n)]
                                            end)
 -- restore embedded C code
 self.code = gsub(self.code,"%#%<(%d+)%>%#",function (n)
                                             return C[tonumber(n)]
                                            end)
end

local function output_tolua_open_Function (name)
  --output('#ifdef __cplusplus\n')
  --output('extern "C" {\n')
  --output('#endif\n')
  output('/* Exported function */')
  output('TOLUA_API int  tolua_'..name..'_open (lua_State* tolua_S);')
  --output('#ifdef __cplusplus\n')
  --output('}\n')
  --output('#endif\n')
  output('\n')
end

-- translate verbatim
function classPackage:preamble ()
 output('/*\n')
 output('** Lua binding: '..self.name..'\n')
 output('** Generated automatically by '..TOLUA_VERSION..'\n')
 output('*/\n\n')

 output('#include <string>\n\n')
 
 if not flags.h then
	output_tolua_open_Function(self.name)
 end

 local i=1
 while self[i] do
  self[i]:preamble()
  i = i+1
 end

	if self:requirecollection(_collect) then
		output('\n')
		output('/* function to release collected object via destructor */')
		output('#ifdef __cplusplus\n')
		for i,v in pairs(_collect) do
		 output('\nstatic int '..v..' (lua_State* tolua_S)')
			output('{')
			output(' '..i..'* self = ('..i..'*) tolua_tousertype(tolua_S,1,0);')
			output('	Mtolua_delete(self);')
			output('	return 0;')
			output('}')
		end
		output('#endif\n\n')
	end

 output('\n')
 output('/* function to register type */')
 output('static void tolua_reg_types (lua_State* tolua_S)')
 output('{')

	if flags.t then
		output("#ifndef Mtolua_typeid\n#define Mtolua_typeid(L,TI,T)\n#endif\n")
	end
	foreach(_usertype,function(n,v)
		if (not _global_classes[v]) or _global_classes[v]:check_public_access() then
			output(' tolua_usertype(tolua_S,"',v,'");')
			if flags.t then
				output(' Mtolua_typeid(tolua_S,typeid(',v,'), "',v,'");')
			end
		end
	 end)
 output('}')
 output('\n')
end

-- register package
-- write package open function
function classPackage:register (pre)
 pre = pre or ''
 push(self)
 output(pre.."/* Open function */")
 output(pre.."TOLUA_API int tolua_"..self.name.."_open (lua_State* tolua_S)")
 output(pre.."{")
 pre_register_code_hook(self, output)
 output(pre.." tolua_open(tolua_S);")
 output(pre.." tolua_reg_types(tolua_S);")
 output(pre.." tolua_module(tolua_S,nullptr,",self:hasvar(),");")
 output(pre.." tolua_beginmodule(tolua_S,nullptr);")
 local i=1
 while self[i] do
  self[i]:register(pre.."  ")
  i = i+1
 end
 output(pre.." tolua_endmodule(tolua_S);")
 post_register_code_hook(self, output)
 output(pre.." return 1;")
 output(pre.."}")

 output("\n\n")
 output("#ifdef __cplusplus\n")
 output('extern "C" {\n')
 output("#endif\n\n")

 output("#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501\n");
 output(pre.."TOLUA_API int luaopen_"..self.name.." (lua_State* tolua_S) {")
 output(pre.." return tolua_"..self.name.."_open(tolua_S);")
 output(pre.."};")
 output("#endif\n\n")
 
 output("#ifdef __cplusplus\n")
 output('}\n')
 output("#endif\n\n")

	pop()
end

-- write header file
function classPackage:header ()
 output('/*\n') output('** Lua binding: '..self.name..'\n')
 output('** Generated automatically by '..TOLUA_VERSION..' on '..date()..'.\n')
 output('*/\n\n')

 if not flags.h then
  output_tolua_open_Function(self.name)
 end
end

-- Internal constructor
function _Package (self)
 setmetatable(self,classPackage)
 return self
end

-- Parse C header file with tolua directives
-- *** Thanks to Ariel Manzur for fixing bugs in nested directives ***
function extract_code(fn,s)
	local code = '\n$#include "'..fn..'"\n'
	s= "\n" .. s .. "\n" -- add blank lines as sentinels
	local _,e,c,t = strfind(s, "\n([^\n]-)[Tt][Oo][Ll][Uu][Aa]_([^%s]*)[^\n]*\n")
	while e do
		t = strlower(t)
		if t == "begin" then
			_,e,c = strfind(s,"(.-)\n[^\n]*[Tt][Oo][Ll][Uu][Aa]_[Ee][Nn][Dd][^\n]*\n",e)
			if not e then
			 tolua_error("Unbalanced 'tolua_begin' directive in header file")
			end
		end
		code = code .. c .. "\n"
	 _,e,c,t = strfind(s, "\n([^\n]-)[Tt][Oo][Ll][Uu][Aa]_([^%s]*)[^\n]*\n",e)
	end
	return code
end

-- Constructor
-- Expects the package name, the file extension, and the file text.
function Package (name,fn)
 local ext = "pkg"

 -- open input file, if any
 local st,msg
 if fn then
   
  st, msg = readfrom(flags.f)
  if not st then
   error('#'..msg)
  end
  local _; _, _, ext = strfind(fn,".*%.(.*)$")
 end
 local code
 if ext == 'pkg' then
  code = prep(st)
 else
  code = "\n" .. read('*a')
  if ext == 'h' or ext == 'hpp' then
   code = extract_code(fn,code)
  end
 end

 -- close file
 if fn then
  readfrom()
 end

 -- deal with include directive
 local nsubst
 repeat
  code,nsubst = gsub(code,'\n%s*%$(.)file%s*"(.-)"([^\n]*)\n',
		function (kind,fn,extra)
			local _, _, ext = strfind(fn,".*%.(.*)$")
			local fp,msg = openfile(fn,'r')
			if not fp then
				error('#'..msg..': '..fn)
			end
			if kind == 'p' then
				local s = prep(fp)
				closefile(fp)
				return s
			end
			local s = read(fp,'*a')
			closefile(fp)
			if kind == 'c' or kind == 'h' then
				return extract_code(fn,s)
			elseif kind == 'l' then
				return "\n$[--##"..fn.."\n" .. s .. "\n$]\n"
			elseif kind == 'i' then
				local t = {code=s}
				extra = string.gsub(extra, "^%s*,%s*", "")
				local pars = split_c_tokens(extra, ",")
				include_file_hook(t, fn, unpack(pars))
				return "\n\n" .. t.code
			else
				error('#Invalid include directive (use $cfile, $pfile, $lfile or $ifile)')
			end
		end)
 until nsubst==0

 -- deal with renaming directive
 repeat -- I don't know why this is necesary
	code,nsubst = gsub(code,'\n%s*%$renaming%s*(.-)%s*\n', function (r) appendrenaming(r) return "\n" end)
 until nsubst == 0

 local t = _Package(_Container{name=name, code=code})
 push(t)
 preprocess_hook(t)
 t:preprocess()
 preparse_hook(t)
 t:parse(t.code)
 pop()
 return t
end


setmetatable(_extra_parameters, { __index = _G })

function prep(file)

  local chunk = {'local __ret = {"\\n"}\n'}
  for line in file:lines() do
     if string.find(line, "^##") then
      table.insert(chunk, string.sub(line, 3) .. "\n")
     else
      local last = 1
      for text, expr, index in string.gmatch(line, "(.-)$(%b())()") do 
        last = index
        if text ~= "" then
          table.insert(chunk, string.format('table.insert(__ret, %q )', text))
        end
        table.insert(chunk, string.format('table.insert(__ret, %s )', expr))
      end
      table.insert(chunk, string.format('table.insert(__ret, %q)\n',
                                         string.sub(line, last).."\n"))
    end
  end
  table.insert(chunk, '\nreturn table.concat(__ret)\n')
  local f,e = loadstring(table.concat(chunk))
  if e then
  	error("#"..e)
  end
  
  setfenv(f, _extra_parameters) -- 5.1 only
  return f()
end
