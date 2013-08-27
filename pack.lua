#!/usr/bin/env lua
-- lua installation directory differs, let the `env` do the $PATH lookup
-- if on windows, screw shebangs, just do `lua.exe pack.lua`
dofile"defs.lua"
local f=assert(io.open(FILE))
local contents=assert(f:read"*a")
f:close()
-- pickup fixed parts of file
local prefix=contents:sub(1,assert(contents:find(START,1,true),"Could not find "..START.." directive")+#START)
local suffix=contents:sub((assert(contents:find(END,1,true),"Could not find "..END.." directive")))
-- read from file
local o=assert(io.open(OUT))
local chars_l={}
local s=o:read"*l"
while s do
	local char,num,hex=s:match"^'(.-)'|(%d*)|(%x*)|"
	local idx
	if num~="" then
		idx=tonumber(num)
	elseif hex~="" then
		idx=tonumber("0x"..hex)
	elseif char~="" then
		idx=unpack_utf8(char:byte(1,#char))
	else
		error"Could not find an ID"
	end
	local w
	local d={}
	local p,b=0,0
	for i=0,HEIGHT-1 do
		local s=o:read"*l":gsub("|$","")
		if not w then
			w=#s
			table.insert(d,w)
		end
		for x=0,w-1 do
			local n=assert(RCHARS[s:sub(x+1,x+1)],"Unknown char "..s:sub(x+1,x+1))
			b=b+n*4^p
			p=p+1
			if p==4 then
				table.insert(d,b)
				p,b=0,0
			end
		end
	end
	if p~=0 then -- if the leftover pixels didn't manage to fill the byte
		table.insert(d,b)
	end
	chars_l[idx]=d
	s=o:read"*l"
end
-- figure out the arrays
local chars,n={},0
for i in pairs(chars_l) do
	n=n+1
	chars[n]=i
end
local blocks_l={}
for _,i in ipairs(chars) do
	blocks_l[math.floor(i/16)]=true
end
local blocks,n={},0
for i in pairs(blocks_l) do
	n=n+1
	blocks[n]=i
end
table.sort(blocks)
local ptrs_l={}
local font_data_t,n,l={},0,0
for _,i in ipairs(chars) do
	ptrs_l[i]=l
	for v=1,#chars_l[i] do
		n,l=n+1,l+1
		font_data_t[n]=(" 0x%02X,"):format(chars_l[i][v])
	end
	n=n+1
	font_data_t[n]="\n"
end
local block_map_t,n={},0
for _,i in ipairs(blocks) do
	n=n+1
	block_map_t[n]=(" 0x%X,"):format(i)
end
local font_ptrs_t,n={},0
for _,i in ipairs(blocks) do
	for v=0,15 do
		n=n+1
		if ptrs_l[i*16+v] then
			font_ptrs_t[n]=(" 0x%X,"):format(ptrs_l[i*16+v])
		else
			font_ptrs_t[n]=" 0,"
		end
	end
	n=n+1
	font_ptrs_t[n]="\n"
end

local font_data="char font_data[] = {\n"..table.concat(font_data_t).."};\n"
local font_ptrs="short font_ptrs[] = {\n"..table.concat(font_ptrs_t).."};\n"
local block_map="int block_map[] = {\n"..table.concat(block_map_t).."};\n"
local f=assert(io.open(FILE,"w"))
assert(f:write(prefix,font_data,font_ptrs,block_map,suffix))
f:close()
