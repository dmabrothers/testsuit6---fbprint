
require 'loverun'



local ffi=require 'ffi'
ffi.cdef("unsigned long clock(void);")

local wndW,wndH=824,980
local fb2=require 'fblove2'(wndW,wndH)
love.window.setTitle(wndW..'x'..wndH)	

local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol
local bswap=bit.bswap 
---------------------------------------------------------------------------

 local tobits=require '8bits'

 local bdfload=require'bdfload' 
 local m1=collectgarbage('count')
 local b1=ffi.C.clock()
 local fnt=bdfload(love.filesystem.getSource( )..'/TerminuX-extraIL-16.bdf') --60mb unifont.bdf 39mb b14.bdf 20mb miniwi-8.bdf
 local b2=ffi.C.clock() 
 print(string.format('bdfload took %gms and %g ram', b2 - b1, collectgarbage('count')-m1))
 
 ---------------------------------------------------------------------------
function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h/256*6, s/255, l/255
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return (r+m)*255,(g+m)*255,(b+m)*255,a
end

local function wordwrap(str, limit)
  limit = limit or 72
  local check
  if type(limit) == "number" then
    check = function(s) return #s >= limit end
  else
    check = limit
  end
  local rtn = {}
  local line = ""
  for word, spaces in str:gmatch("(%S+)(%s*)") do
    local s = line .. word
    if check(s) then
      table.insert(rtn, line .. "\n")
      line = word
    else
      line = s
    end
    for c in spaces:gmatch(".") do
      if c == "\n" then
        table.insert(rtn, line .. "\n")
        line = ""
      else
        line = line .. c
      end
    end
  end
  table.insert(rtn, line)
  return table.concat(rtn)
end
---------------------------------------------------------------------------

local rectum2={}
local band=bit.band

local function chargen3(char) -- 111-39= 72mb 449ms for b14.bdf      example.txt 
  local tmp={}                -- 182-60=122mb 848ms for unifont.bdf  example.txt
                              --  25-20=  5mb  21ms for miniwi-8.bdf example.txt
  if fnt[char]==false or fnt[char]==nil then return tmp end
  local w=fnt[char].BBX[1]
  local h=fnt[char].BBX[2]
  for y=h,1,-1 do
   local  bit=tobits(fnt[char].BITMAP[y])
     for x=1,w do 
      if bit[x]==1 then tmp[#tmp+1]=x-1+fnt[char].BBX[3] tmp[#tmp+1]=(y-h)-fnt[char].BBX[4]  end
     end 
   end
  return tmp
end

local function chargen3b(char) --  84-39=45mb 323ms for b14.bdf      example.txt  
  local tmp={}                 -- 145-60=85mb 603ms for unifont.bdf  example.txt
                               --  25-20= 5mb  21ms for miniwi-8.bdf example.txt
  if fnt[char]==false or fnt[char]==nil then return tmp end
  local w=fnt[char].BBX[1]
  local h=fnt[char].BBX[2]
  for y=h,1,-1 do
   local size=8 if fnt[char].BITMAP[y]>256 then size=16 end
   local k=2^size
     for x=1,w do 
      if rshift(band(lshift(fnt[char].BITMAP[y],x),k),size ) ==1 then tmp[#tmp+1]=x-1+fnt[char].BBX[3] tmp[#tmp+1]=(y-h)-fnt[char].BBX[4]  end
     end 
   end
  return tmp
end

local function chargen3c(char) --  84-39=45mb 311ms for b14.bdf      example.txt 
  if fnt[char]==false or fnt[char]==nil then return nil end --596ms 591ms
  local tmp={}                 -- 145-60=85mb 613ms for unifont.bdf  example.txt
                               --  25-20= 5mb  21ms for miniwi-8.bdf example.txt
 -- if fnt[char]==false or fnt[char]==nil then return tmp end  
  local w=fnt[char].BBX[1]
  local h=fnt[char].BBX[2]
  local size=8 if w>8 then size=16 end
   local k=2^size
  for y=h,1,-1 do
     for x=1,w do 
      if rshift(band(lshift(fnt[char].BITMAP[y],x),k),size ) ==1 then tmp[#tmp+1]=x-1+fnt[char].BBX[3] tmp[#tmp+1]=(y-h)-fnt[char].BBX[4]  end
     end 
   end
  return tmp
end

local function chargen3f(char) -- 44-39= 5mb 208ms for b14.bdf      example.txt  
                               -- 70-60=10mb 375ms for unifont.bdf  example.txt
                               -- 20-20= 0mb  22ms for miniwi-8.bdf example.txt
  --if fnt[char]==false or fnt[char]==nil then return tmp end --эээ, как оно вообще тут работало?
  if fnt[char]==false or fnt[char]==nil then return nil end 
  --if fnt[char]==false or fnt[char]==nil then return false end 
  local w=fnt[char].BBX[1]
  local h=fnt[char].BBX[2]
  local size=8 if w>8 then size=16 end
  local k=2^size
  local c=0

  for y=h,1,-1 do for x=1,w do if rshift(band(lshift(fnt[char].BITMAP[y],x),k),size ) ==1 then c=c+2 end end end
  local tmp=ffi.new('char[?]',c+1)
  tmp[0]=c     -- если в глифе будет больше 63(?) закрашеных пикселей - будет жопа
  tmp[0]=c-127 -- а вот теперь можно и 127 покрасить
  c=1
  for y=h,1,-1 do
     for x=1,w do 
      if rshift(band(lshift(fnt[char].BITMAP[y],x),k),size ) ==1 then tmp[c]=x-1+fnt[char].BBX[3] tmp[c+1]=(y-h)-fnt[char].BBX[4] c=c+2  end
     end 
   end
   return tmp
end

 local glyph=ffi.typeof("struct { int size; char pix[?]; }")
local function chargen3fs(char) -- 44-39= 5mb 208ms for b14.bdf      example.txt  
                               -- 70-60=10mb 375ms for unifont.bdf  example.txt
                               -- 20-20= 0mb  22ms for miniwi-8.bdf example.txt
  --if fnt[char]==false or fnt[char]==nil then return tmp end --эээ, как оно вообще тут работало?
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



local function chargenall()
  for i=0,65536 do
    rectum2[i]=nil
    rectum2[i]=chargen3fs(i)
  end
  
end

require 'utf'


local function gprint3ufmb(txt,x,y,x2,color)  
  local state = 0
  local codep =  0;
  local offset = 1;
  local k=0
  local count=0
  local wcount=0
    while offset <= #txt do
    --  if count>rshift(wndW,2)-1+k then break end
    
    
    
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
          for j=0,rectum2[codep].size-1,2 do --for chargen3f
            fb2.buf[rectum2[codep].pix[j+1]+y ]
            [rectum2[codep].pix[j]+x+wcount+k]=color end  
            
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


end
----------------------------------------------------------------------------
local scroll=0
local printer={}
printer.p=0
printer.m=0



--fb2.graphics.setBackgroundColor(0xFF303030)
fb2.graphics.setBackgroundColor(bswap(0xaaaaaaFF))
--fb2.graphics.setBackgroundColor(bswap(0x303030FF))
--fb2.setfg(0xFF99BB66)
fb2.setfg(0xFF444499)
--local color=0xFFbbbbbb
local color=0x00bbbbbb  
  local tbox={20,20,784,940} --x,y,w,h 
local function printer2(fb)
    if printer.p==0 then return else printer.p=0 end
    
    local h=fnt.BBX[2]--+fnt.BBX[4]--+2--8
    fb2.fill()
    fb2.drawRect('line',tbox[1]-1,tbox[2]-1,tbox[3]+1,tbox[4]+1)
     -- for i=1,#printer do 
     -- for i=1+rshift(scroll,4),#printer do
     local sc=0-math.floor(scroll/h)
     if sc<=0 then sc=1 end
      for i=sc,#printer do 
     -- local tmp= i*7*scl+scroll
     if (i*h+scroll+tbox[2]) >tbox[2] and (i*h+scroll) < tbox[4]-1 then gprint3ufmb(printer[i],tbox[1],i*h+scroll+tbox[2],tbox[3],color) end
     if (i*h+scroll) >tbox[4]+tbox[2] then break end
    end
  
    fb2.refresh()
    printer.m=printer.m+1
    if printer.m==1000 then printer.m=0 collectgarbage('collect') end
  end
  
  

  
--------------------------------------------------


local scale=1
local time = 0

function love.draw()
   time =  ffi.C.clock()
  --fb2.setfg(HSL(80*math.sin(time*0.00001),100*math.cos(time*0.0005),200))
 -- printer.p=1
  printer2()
 love.graphics.setBackgroundColor(HSL(30*math.sin(time*0.00001),200*math.cos(time*0.0005),40))
 
 
  fb2.draw(0,0,scale)
  
love.graphics.print(tbox[1]..' '..tbox[2]..' '..tbox[3]..' '..tbox[4])

  love.graphics.print('scroll: '..scroll,400,0)
   love.graphics.print('#printer : '..#printer,500,0)
   
    fps=math.floor(1/love.timer.getAverageDelta())
	love.graphics.print('fps:         '..fps,300,0)
  love.graphics.print('ss',300,15)
  love.window.setTitle(fps)
end

function love.update(dt)

end

function love.quit()
--  require("jit.p").stop()
  print(jit.status() )
  --require("jit.v").stop()
end


---[[
function love.resize(w,h)
--wndW,wndH=w,h  
wndW,wndH=rshift(w,scale-1),rshift(h,scale-1)
love.window.setTitle(wndW..'x'..wndH)	
 tbox[3]=wndW-20-tbox[1]
 tbox[4]=wndH-20-tbox[2]
 fb2.reinit(wndW,wndH)
 printer.p=1
end
--]]

local function loadtxt(file)
  scroll=0
  file:open('r')
  local y=0
  local fontH=7
  tbl={}
  printer={}
  printer.m=0
 -- love.graphics.setBackgroundColor( 0x30, 0x32, 0x3A)--0x3a3230
  --setColor(0xBB,0xBB,0xBB)
  for line in file:lines() do
  printer[#printer+1]=line
  --  tbl[#tbl+1]=loadstring( [==[aprint(']==]..line..[==[',0,]==]..tostring(y)..')' )
  --  y=y+fontH
  end
  file:close()

  collectgarbage('collect')
  printer.p=1
  printer2()
  printer.p=1
  printer2()
end

local function loadfnt(fname)
  for i=1,#fnt do fnt[i]=nil end
  collectgarbage('collect')
  fnt=bdfload(fname)
  chargenall()
  printer.p=1 
end
function love.filedropped(file)
  fname=file:getFilename() 
  if fname:find('.bdf',#fname-3) then loadfnt(fname) print(fname)
    else loadtxt(file)  end
end

function love.mousemoved( x, y, dx, dy, istouch )
  if love.mouse.isDown(1)==true then scroll=scroll+dy 
    printer.p=1 
  end
end

function love.wheelmoved(x, y)
    if y > 0 then
        scroll=scroll+40
    elseif y < 0 then
        scroll=scroll-40
    end
    printer.p=1 
end

local function setwnd()
  local W,H,t = love.window.getMode() 	--потому что все свойства окна, любовно настроенные в conf.lua
	love.window.setMode(wndW*scale,wndH*scale,t)			-- так что сначала достаём её юзая getMode, меняем нужные параметры и скармливаем обратно
end

function love.keypressed( key, scancode, isrepeat )
  if key=='end' then scroll=wndH-#printer*8   printer.p=1 end
  if key=='home' then scroll=0                printer.p=1 end
  if key=='pageup' then scroll=scroll+wndH-16   printer.p=1 end
  if key=='pagedown' then scroll=scroll-wndH+16  printer.p=1 end
  
  if key=='x' then require("jit.p").start(nil, 'profile.txt') end
  if key=='c' then require("jit.p").stop() end
  if key=='r' then print(collectgarbage('count'),collectgarbage('collect'),collectgarbage('count') )end
  if key=='=' then scale=scale+1 setwnd() end
  if key=='-' and scale>1 then scale=scale-1 setwnd() end
end

local function runthread()
  local str=[===[
  local sdl = require 'sdl2'
local ffi = require 'ffi'
local C = ffi.C

sdl.init(sdl.INIT_VIDEO)

local window = sdl.createWindow("Hello Lena",
                                sdl.WINDOWPOS_CENTERED,
                                sdl.WINDOWPOS_CENTERED,
                                512,
                                512,
                                sdl.WINDOW_SHOWN)

local windowsurface = sdl.getWindowSurface(window)

local image = sdl.loadBMP("lena.bmp")

sdl.upperBlit(image, nil, windowsurface, nil)

sdl.updateWindowSurface(window)
sdl.freeSurface(image)

local running = true
local event = ffi.new('SDL_Event')
while running do
sdl.delay(10)
   while sdl.pollEvent(event) ~= 0 do
      if event.type == sdl.QUIT then
         running = false
      end
   end
end

sdl.destroyWindow(window)
sdl.quit()
  ]===]
  thread = love.thread.newThread( str )
  thread:start( )
end

function love.load()
  love.graphics.setBackgroundColor( 0x20, 0x20, 0x20)
 -- require("jit.v").start("my_dump-fficlock.txt")
 -- require("jit.p").start(nil, 'profile.txt')
 --print(love.filesystem.getSource( )..'/b14.bdf')
 local t1=ffi.C.clock()
   chargenall()
 local t2=ffi.C.clock() 
 print(string.format('t2-t1 took %gms', t2 - t1))
-- for i=0,rectum2[65][0] do io.write(rectum2[65][i],' ') end io.write '\n'
   printer.p=1
   collectgarbage('collect')
  loadtxt(love.filesystem.newFile('example.txt' ) )
  local sdl = ffi.load 'SDL2'

ffi.cdef [[
typedef void SDL_Window;

SDL_Window* SDL_GL_GetCurrentWindow (void);

void SDL_MinimizeWindow (SDL_Window* window);
void SDL_SetWindowTitle(SDL_Window* window, const char *title);
int SDL_SetWindowGammaRamp(SDL_Window* window, const uint16_t* red, const uint16_t* green, const uint16_t* blue);

]]
--gamma=ffi.new('const uint16_t[3]',{500,1000,2000})
-- sdlWindow = sdl.SDL_GL_GetCurrentWindow()
--sdl.SDL_MinimizeWindow(sdlWindow)
--sdl.SDL_SetWindowTitle(sdlWindow,'fuck')
--print(sdl.SDL_SetWindowGammaRamp(sdlWindow,gamma,gamma+1,gamma+2) )

--runthread()
end