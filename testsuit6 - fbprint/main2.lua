local wndW,wndH=love.window.getMode()
local fb
if not fb2 then  fb=require 'fblove_strip'(wndW,wndH) 
else fb=fb2 end
fb.setbg(0xFFaaaaaa) -- ARGB
local rol,lshift,ror,rshift=bit.rol,bit.lshift,bit.ror,bit.rshift
 s=require 'serpent' 
local text=s.block(getfenv(),{nocode = true,sortkeys = true, comments= false})

--[[
  TomorrowNight = {
    Background  = H'1d1f21',
    CurrentLine = H'282a2e',
    Selection   = H'373b41',
    Foreground  = H'c5c8c6', --everything else
    Comment     = H'969896',
    Red         = H'cc6666', --numbers
    Orange      = H'de935f',
    Yellow      = H'f0c674',
    Green       = H'b5bd68', --string literal
    Aqua        = H'8abeb7', --operators, separators etc.
    Blue        = H'81a2be', --keywords
    Purple      = H'b294bb',
  },
--]]
fb.setbg(0xFF211f1d)
local fbprint=require 'fbprint'
local font='b14.bdf' --60mb unifont.bdf 39mb b14.bdf 20mb miniwi-8.bdf TerminuX-extraIL-16.bdf
if love.filesystem then font=love.filesystem.getSource( )..'/fonts/'..font
  else font='fonts/'..font
end
local fnt=fbprint.bdfload(font) 
--local fnt=require'fonts/terminux' 
--local fnt=require'fonts/miniwi-8' fnt.BBX={4,8,0,-3} fb.setbg(0xFF211f1d)
--print(s.dump(fnt,{nocode = true,sortkeys = true, comments= false}))
fnt=fbprint.chargenall(fnt,fbprint.chargen) 

--local text=s.block(fnt,{nocode = true,sortkeys = true, comments= false})
local scroll=0

local ntable={[0]=0}
local n=0
while n do  n=text:find('\n',n+1)  ntable[#ntable+1]=n end

fbprint.printer=function(txt,x1,y1,x2,color)
    x1=x1 or 0
    x2=x2 or wndW-x1
    
    color = color or 0xFF000000
    local n=0
    local h=fnt.BBX[2]
    y1=y1 or h
    local offset=ntable[scroll]
     while offset and n<wndH-20 do
    offset=fbprint.fbprint(txt,offset+1,fnt,fb,x1,y1+n,x2,color)
    n=n+h
    end
  end
  
  fbprint.printer2=function(txt,x1,y1,x2,color)
    x1=x1 or 0
    x2=x2 or wndW-x1
    
    color = color or 0xFFc6c8c5
    local h=fnt.BBX[2]
    y1=y1 or 0
     for i=1,(wndH-20)/h do
       if ntable[scroll+i] then
          fbprint.fbprint(txt,ntable[scroll+i]+1,fnt,fb,x1,y1+i*h,x2,color)
        end
    end
  end
  
  fbprint.print=function(txt,x1,y1,x2,color)
    x1=x1 or 0
    x2=x2 or wndW-x1
    
    color = color or 0xFFFFFFFF
    local n=0
    local h=fnt.BBX[2]
    y1=y1 or 0  y1=y1+h
    local offset=0
     while offset and n<wndH-20 do
    offset=fbprint.fbprint(txt,offset+1,fnt,fb,x1,y1+n,x2,color)
    n=n+h
    end
  end

local wake=true
local function lazyprinter()
  fb.fill()
  fbprint.printer2(text,10)
  	if nanolove then fps=love.timer.getAverageDelta()
    else fps=math.floor(1/love.timer.getAverageDelta()) 
    end
    fbprint.print('fps: '..fps..'\n'..#ntable..'/'..scroll,wndW-120,0,nil,0xFF81a2be)
    fb.refresh() 
end

function love.draw()

  if wake then wake=false lazyprinter() end
	

	fb.draw(0,0,1) 
end

function love.resize(w,h)
wndW,wndH=w,h  

love.window.setTitle(wndW..'x'..wndH..' scale ')	
 fb.reinit(wndW,wndH) -- переиницализируем под новое разрешение
wake=true
end

function love.wheelmoved(x, y)
    if y > 0 then
        scroll=scroll-1
    elseif y < 0 then
        scroll=scroll+1
    end
    if scroll<0 then scroll=0 end
    wake=true
end
local function round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end
function love.mousemoved( x, y, dx, dy, istouch )
  if love.mouse.isDown(1)==true then scroll=scroll- round(dy/2) 
   wake=true 
  end
   if scroll<0 then scroll=0 end
   
end

function love.filedropped(file)
  fname=file:getFilename() 
local fr=assert(io.open(fname,'rb')) 
 text=fr:read('*a')
fr:close()
scroll=0
local n=0
ntable={[0]=0}
while n do  n=text:find('\n',n+1)  ntable[#ntable+1]=n end
wake=true
end