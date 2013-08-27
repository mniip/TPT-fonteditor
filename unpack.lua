#!/usr/bin/env lua
-- lua installation directory differs, let the `env` do the $PATH lookup
-- if on windows, screw shebangs, just do `lua.exe unpack.lua`
dofile"defs.lua"
local f=assert(io.open(FILE))
local contents=assert(f:read"*a")
f:close()
local data=contents:sub(assert(contents:find(START,1,true),"Could not find "..START.." directive")+#START,assert(contents:find(END,1,true),"Could not find "..END.." directive")-1)
local function parse_array(s)
	local t,i={},0
	for n in s:gsub("/%*.-%*/",""):gmatch"[^,]+" do
		if n:match"%S" then
			-- TODO: do we need octal?
			i=i+1
			t[i]=assert(tonumber(n),"Could not parse '"..n.."'")
		end
	end
	return t,i
end
local font_data,ndata=parse_array(assert(data:match"char%s+font_data%s*%[%s*%]%s*=%s*{([^}]+)","Could not find font_data"))
local font_ptrs,nptrs=parse_array(assert(data:match"short%s+font_ptrs%s*%[%s*%]%s*=%s*{([^}]+)","Could not find font_ptrs"))
local block_map,nmap=parse_array(assert(data:match"int%s+block_map%s*%[%s*%]%s*=%s*{([^}]+)","Could not find block_map"))
local f=assert(io.open(OUT,"w"))
assert(f:write"") -- test
for block=1,nmap do
	for i=0,15 do
		local ptr=assert(font_ptrs[block*16-15+i],"font_ptrs too short")
		local idx=block_map[block]*16+i
		if ptr~=0 or idx==0 then
			if idx>31 then
				f:write("'"..string.char(pack_utf8(idx)).."'")
			else
				f:write"''"
			end
			f:write("|",idx,"|",hexlify(idx),"|",concat(" ",vararg_apply(hexlify,pack_utf8(idx))),"\n")
			local w=assert(font_data[ptr+1],"font_data too short")
			for y=0,HEIGHT-1 do
				for x=0,w-1 do
					local n=math.floor(assert(font_data[ptr+2+math.floor((y*w+x)/4)],"font_data too short")/4^((y*w+x)%4))%4
					f:write(CHARS[n])
				end
				f:write'|\n'
			end
		end
	end
end
f:close()
