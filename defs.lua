HEIGHT=12
FILE="../font.h"
OUT="rawfont.txt"
START="//#DATA"
END="//#END_DATA"
CHARS={[0]=' ','-','+','#'}
RCHARS={[' ']=0,['-']=1,['+']=2,['#']=3}

-- utility functions

function vararg_apply(f,a,...)
	if select('#',...)>0 then
		return f(a),vararg_apply(f,...)
	else
		return f(a)
	end
end

function hexlify(s)
	return ("%X"):format(s)
end

function concat(s,...)
	return table.concat({...},s)
end

function pack_utf8(x)
	assert(x<=0x10FFFF and x>=0,"invalid codepoint")
	if x<0x80 then
		return x
	elseif x<0x800 then
		return 0xC0+math.floor(x/64),0x80+x%64
	elseif x<0x10000 then
		return 0xE0+math.floor(x/4096),0x80+math.floor(x/64)%64,0x80+x%64
	else
		return 0xF0+math.floor(x/262144),0x80+math.floor(x/4096)%64,0x80+math.floor(x/64)%64,0x80+x%64
	end
end

function unpack_utf8(a,b,c,d)
	-- TODO: proper checking?
	if a<0x80 then
		return a
	elseif a<0xE0 then
		return (a%64)*64+b%64
	elseif a<0xF0 then
		return (a%32)*4096+(b%64)*64+c%64
	else
		return (a%16)*262144+(b%64)*4096+(c%64)*64+d%64
	end
end
