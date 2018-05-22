local ffi=require 'ffi'
local lshift, rshift, rol, bswap = bit.lshift, bit.rshift, bit.rol, bit.bswap
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local bnot = bit.bnot
-------------------------------------------------------------------------------
local function parse2(filename)
  local function ngmatch(str,str2)
  local n=1
  local t={}
   while true do
      local a,b = str:find(str2,n)
      if not(a and b) then break end
      local out,c=0,0
      n=b+1
      for i=b,a,-1 do
        if str:byte(i)==45 then out=0-out
          else out=out+(str:byte(i)-48)*10^c end
        c=c+1
      end
      t[#t+1]=out
    end
    return t
end
  
 local file = io.open(filename)
 local font={}
 local str=''
 font.maxchar=0
  while true do
	str= file:read('*l')
	if not str then break end
	
  if str:find('FONTBOUNDINGBOX') then
    font.BBX=ngmatch(str,'[-]?%d+')
  end
  
	if str:find('STARTCHAR') then
	 str=file:read()	
	 local i=tonumber( str:match('%d+') )	
	 font[i]={}
    if i> font.maxchar then font.maxchar = i end

	 str=file:read()	 
	 font[i].SWIDTH=ngmatch(str,'%d+')

	 -----------копипаста рулит)
	 str=file:read()	 
	 font[i].DWIDTH=ngmatch(str,'%d+')

	 ------------ 
	 str=file:read()	 
	 font[i].BBX=ngmatch(str,'[-]?%d+')

	------------- 
	 file:read()
	 font[i].BITMAP={} 

	  for j=1,font[i].BBX[2] do
		str=file:read()
		font[i].BITMAP[j]=tonumber(str,16)

	  end

	end	
	
  end

 file:close()
 return font 
end
-------------------------------------------------------------------------------
 local glyph=ffi.typeof("struct { int size; int8_t pix[?]; }")
local function chargen3fs(fnt,char) 
  if fnt[char]==false or fnt[char]==nil then return nil end 
  --if fnt[char]==false or fnt[char]==nil then return false end 
  local w=fnt[char].BBX[1]
  local h=fnt[char].BBX[2]
  local size=8 if w>8 then size=16 end
  local k=2^size
  local c=0

  for y=h,1,-1 do for x=1,w do if rshift(band(lshift(fnt[char].BITMAP[y],x),k),size ) ==1 then c=c+2 end end end
  --local tmp=ffi.new('char[?]',c+1)
 
  local tmp=glyph(c)
  tmp.size=c   
  c=0
  for y=h,1,-1 do
     for x=1,w do 
      if rshift(band(lshift(fnt[char].BITMAP[y],x),k),size ) ==1 then tmp.pix[c]=x-1+fnt[char].BBX[3] tmp.pix[c+1]=(y-h)-fnt[char].BBX[4] c=c+2  end
     end 
   end
   return tmp
end

local function chargenall(fnt,chargen)
  fnt.glyph={}
  for i=0,fnt.maxchar do
    fnt.glyph[i]=nil
    fnt.glyph[i]=chargen(fnt,i)
  end
  return fnt
end
-------------------------------------------------------------------------------
--https://williamaadams.wordpress.com/2012/06/16/messing-around-with-utf-8-in-luajit/
local UTF8_ACCEPT = 0
local UTF8_REJECT = 12
 
local utf8d = ffi.new("const uint8_t[364]", {
  -- The first part of the table maps bytes to character classes that
  -- to reduce the size of the transition table and create bitmasks.
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
   8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,
 
  -- The second part is a transition table that maps a combination
  -- of a state of the automaton and a character class to a state.
   0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
  12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
  12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
  12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
  12,36,12,12,12,12,12,12,12,12,12,12,
});
 
local function decode_utf8_byte(state, codep, byte)
  local ctype = utf8d[byte];
  if (state ~= UTF8_ACCEPT) then
    codep = bor(band(byte, 0x3f), lshift(codep, 6))
  else
    codep = band(rshift(0xff, ctype), byte);
  end
  state = utf8d[256 + state + ctype];
  return state, codep;
end

-------------------------------------------------------------------------------
local function gprint3ufmb(txt,offset,fnt,fb,x,y,x2,color)  
  local state = 0
  local codep =  0;
  --local offset = 1;
  local k=0
  local count=0
  local wcount=0
  
    while offset <= #txt do
    --  if count>rshift(wndW,2)-1+k then break end
    
    
      if  txt:byte(offset)==10 then  break end
       if  txt:byte(offset)==45 and  txt:byte(offset+1)==45 then  color=0xFF969896 end
       state, codep = decode_utf8_byte(state, codep, txt:byte(offset))
      offset = offset + 1
      if state == 0 then 
        if fnt[codep] then  
          if wcount>x2-fnt[codep].DWIDTH[1] then break end 
          
          --tab
          if codep==9 then wcount=wcount+fnt[32].DWIDTH[1]+fnt[32].DWIDTH[1] goto tab end
          --[[
          --for j=1,#rectum2[codep]-1,2 do 
          for j=1,rectum2[codep][0]+127-1,2 do --for chargen3f
            fb2.buf[rectum2[codep][j+1]+y ]
            [rectum2[codep][j]+x+wcount+k]=color end
           --]] 
          for j=0,fnt.glyph[codep].size-1,2 do --for chargen3f
            fb.buf[fnt.glyph[codep].pix[j+1]+y ]
            [fnt.glyph[codep].pix[j]+x+wcount+k]=color end  
            
          wcount=wcount+fnt[codep].DWIDTH[1]--fnt[codep].BBX[1]+fnt[codep].BBX[3]
        --  if codep==1102 or codep==1099  
        --  or codep==1044  then k=k+1 end-- Эти буквы занимают 4 пикселя.. добавляем лишний пиксель к координатам следующего символа
        --  if k>0 and codep==32 then k=k-1 end --и укорачиваем следующий за словом пробел на пиксель:)
         ::tab::
         else wcount=wcount+fnt[32].DWIDTH[1] end
      elseif state == 12 then 
      --
      end
    
    end
return offset

end

return {
  bdfload=parse2,
  chargen=chargen3fs,
  chargenall=chargenall,
  fbprint=gprint3ufmb,
  }