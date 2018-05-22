local function nanolove(w,h,main)

local sdl = require 'sdl2/init'
local ffi = require 'ffi'
local C = ffi.C
ffi.cdef("unsigned long clock(void);")
love={} love.window={} love.timer={} 
local tick=0
local seconds=0
local fps=0

function love.window.getMode()
	return w,h
end


function love.timer.getAverageDelta()
	return fps--dt*0.001
end

love.mouse={}
local mousekey=0
function love.mouse.isDown(key)
	return key==mousekey
	--return mouskey==bit.lshift(1,key-1)
end

sdl.init(sdl.INIT_VIDEO)
local sdlWindow = sdl.createWindow("nanolove",sdl.WINDOWPOS_CENTERED,sdl.WINDOWPOS_CENTERED,
                                w,h,sdl.WINDOW_RESIZABLE)-- bit.bor( sdl.WINDOW_OPENGL, sdl.WINDOW_RESIZABLE))

local wait2=0
function love.window.setTitle(str)
	if wait2~=seconds then 
		sdl.setWindowTitle(sdlWindow,str)
		wait2=seconds
	end	
end




--sdl.setHint('SDL_HINT_FRAMEBUFFER_ACCELERATION','0')
--sdl.setHint('SDL_HINT_IDLE_TIMER_DISABLED','0')
--sdl.setHint('SDL_RENDERER_PRESENTVSYNC','1')


-----------------------------------------------------------------------
  ---------init-----------------------
  local width,heigh=w,h 
 -- local sdlWindow--sdl.gL_GetCurrentWindow() --тебя нужно вызыввать лишь один раз при запуске... так что оставлю вызов здеся.
  local wndsurf = 0
  --imagedata=sdl.createRGBSurface(0,width,heigh,32,0,0,0,0) -я передумал использовать блиттинг и буду рисовать сразу на повехрности окна
  
  ffi.cdef[[typedef struct { uint8_t r, g, b, a; } rgba_pixel;]]

  local buf={}
  local bufrgba={}
  
  local bgcolorptr8=ffi.new('uint8_t[4]',0x00) --после того как тут появлился такой замечательный тупедеф... ну ты понел
  local bgcolorptr=ffi.cast("uint32_t *",bgcolorptr8)
  local bgcolor=0xFF000000
  --local bg=ffi.new('uint32_t[?]',width,bgcolor)
  
  ----------fb functions--------------
  local function init (w,h)
   -- width,heigh=wd,hg -- вообще-то, sdlWindow уже содержит актуальные w,h  
    for i=1,#buf do
      buf[i]=nil
      bufrgba[i]=nil
    end
    wndsurf = sdl.getWindowSurface(sdlWindow)--sdl.getWindowSurface(sdlWindow) --windowsurface.format.BitsPerPixel
    width,heigh=wndsurf.w, wndsurf.h
    buf[0]=ffi.cast("uint32_t *",wndsurf.pixels)
    bufrgba[0]=ffi.cast('rgba_pixel *',wndsurf.pixels)
	for i=1,heigh-1 do
		buf[i]=buf[0]+width*i
		bufrgba[i]=bufrgba[0]+width*i
	end
	
  --  bg=ffi.new('uint32_t[?]',width,bgcolor) --ты тоже стал ненужным ... а может и не стал, хуй знает что быстрее
    collectgarbage('collect')
    if love.resize then love.resize(w,h) end
  end
  
  local function fill(color) -- работает чуть быстрее чем  оригинал ... ага, на 1 фпс больше в 2560х1440 :)
   color =color or bgcolor
  sdl.fillRect(wndsurf,nil,color)
  end

  local function refresh()
   -- image:refresh() -- рефрешить больше ничего ненадо, но оставлю заглушку для совместимости )
   sdl.updateWindowSurface(sdlWindow) 
  end
  
  local function draw(x,y,sc)
   --sdl.updateWindowSurface(sdlWindow) 
   --print( ffi.string(sdl.getError()))
  end
  


  local function g_setBackgroundColor(r, g, b, a ) --or table RGBA
    local a=a or 0xFF
    if not g then bgcolorptr[0]=r 
      else bgcolorptr8[0]=r bgcolorptr8[1]=g bgcolorptr8[2]=b bgcolorptr8[3]=a  
    end
  bgcolor =bgcolorptr[0] 
  --for i=0,width-1 do bg[i]=bgcolor end -- и ты тоже стал ненужным
  end
------------------------------------------------------------------------
init(w,h)
local function dummy() end
fb2={buf=buf,bufrgba=bufrgba,

          fill=fill,
          reinit=dummy,
          refresh=refresh,
          draw=draw,
          setbg=g_setBackgroundColor,
         }
require(main)

local wev={
    'SDL_WINDOWEVENT_NONE         ',
    'SDL_WINDOWEVENT_SHOWN        ',
    'SDL_WINDOWEVENT_HIDDEN       ',
    'SDL_WINDOWEVENT_EXPOSED      ',
    'SDL_WINDOWEVENT_MOVED        ',
    'SDL_WINDOWEVENT_RESIZED      ',
    'SDL_WINDOWEVENT_SIZE_CHANGED ',
    'SDL_WINDOWEVENT_MINIMIZED    ',
    'SDL_WINDOWEVENT_MAXIMIZED    ',
    'SDL_WINDOWEVENT_RESTORED     ',
    'SDL_WINDOWEVENT_ENTER        ',
    'SDL_WINDOWEVENT_LEAVE        ',
    'SDL_WINDOWEVENT_FOCUS_GAINED ',
    'SDL_WINDOWEVENT_FOCUS_LOST   ',
    'SDL_WINDOWEVENT_CLOSE        '
		}
dev={'SDL_DROPFILE     ',
	 'SDL_DROPTEXT     ',
	 'SDL_DROPBEGIN    ',
	 'SDL_DROPCOMPLETE '
	 }
local function log(p,...)
if p==1 then io.write('\n') end
io.write(...)

end
log=dummy

local function clock()
seconds=seconds+1
end

local count=0						
local running = true
local event = ffi.new('SDL_Event')
sdl.eventState(sdl.DROPFILE, sdl.ENABLE);
local lasttime,lt2=0,0

while running do
  ::sleep::
local t1=sdl.getTicks()
if t1<lasttime + 1000/60 then sdl.delay(1)  else  love.draw() lasttime=t1 count=count+1 end
love.draw() lasttime=t1 count=count+1
if t1> lt2+ 1000 	 then clock() lt2=t1 fps=count  count=0 end
   while sdl.pollEvent(event) ~= 0 do
      if event.type == sdl.QUIT then
         running = false
      end
	  
	  if event.type == sdl.MOUSEMOTION  then
		if love.mousemoved then love.mousemoved( event.motion.x, event.motion.y, event.motion.xrel, event.motion.yrel) end
		mousekey=event.motion.state 
        log(1, event.motion.timestamp,'\t',event.motion.x,'\t',event.motion.y ,'\t',event.motion.xrel,'\t',event.motion.yrel ,'\t',event.motion.state )
      end
	  
	   if event.type == sdl.MOUSEWHEEL  then
		if love.wheelmoved then love.wheelmoved( event.wheel.x, event.wheel.y) end
        log(1, event.wheel.timestamp,'\tSDL_MOUSEWHEEL\t',event.wheel.x,'\t',event.wheel.y )
      end
	  
		if event.type == sdl.WINDOWEVENT then 
		log(1,event.window.timestamp,'\t\t',wev[event.window.event+1],event.window.data1,'\t',event.window.data2)
			if event.window.event == sdl.WINDOWEVENT_RESIZED then 
				windowsurface = sdl.getWindowSurface(sdlWindow)
				init(event.window.data1,event.window.data2) 
				log(2,'\tdone\n') 
			end
				
			if event.window.event == sdl.WINDOWEVENT_HIDDEN then
				log(2,'\t\tdone\n')
			end
			
			if event.window.event == sdl.WINDOWEVENT_EXPOSED then
				log(2,'\t\tdone\n') 
			end
      refresh()
		end
		
		if event.type == sdl.DROPFILE then
		local fname=ffi.string(event.drop.file)
		if love.filedropped then love.filedropped({f=fname, getFilename=function(t) return t.f end }) end
		log(1,event.drop.timestamp,'\t\t',event.drop.type,' ',fname,'\n')
		sdl.free(event.drop.file)
		end
   end

end

sdl.destroyWindow(sdlWindow)
sdl.quit()

end

return nanolove
--[[
enum {
SDL_BUTTON_LEFT     = 1,
SDL_BUTTON_MIDDLE   = 2,
SDL_BUTTON_RIGHT    = 3,
SDL_BUTTON_X1       = 4,
SDL_BUTTON_X2       = 5,
SDL_BUTTON_LMASK    = 1 << (SDL_BUTTON_LEFT-1),
SDL_BUTTON_MMASK    = 1 << (SDL_BUTTON_MIDDLE-1),
SDL_BUTTON_RMASK    = 1 << (SDL_BUTTON_RIGHT-1),
SDL_BUTTON_X1MASK   = 1 << (SDL_BUTTON_X1-1),
SDL_BUTTON_X2MASK   = 1 << (SDL_BUTTON_X2-1),
};

{
    Uint32 type;
    Uint32 timestamp;
    Uint32 windowID;
    Uint32 which;
    Uint32 state;
    Sint32 x;
    Sint32 y;
    Sint32 xrel;
    Sint32 yrel;
} SDL_MouseMotionEvent;

ffi.cdef [[
typedef struct SDL_Surface
{
    Uint32 flags;
    SDL_PixelFormat *format;
    int w, h;
    int pitch;
    void *pixels;
    void *userdata;
    int locked;
    void *lock_data;
    SDL_Rect clip_rect;
    struct SDL_BlitMap *map;
    int refcount;
} SDL_Surface;

typedef struct SDL_Window SDL_Window;
SDL_Window * SDL_CreateWindow(const char *title, int x, int y, int w,int h, Uint32 flags);
typedef enum
{
    SDL_WINDOWEVENT_NONE,
    SDL_WINDOWEVENT_SHOWN,
    SDL_WINDOWEVENT_HIDDEN,
    SDL_WINDOWEVENT_EXPOSED,
    SDL_WINDOWEVENT_MOVED,
    SDL_WINDOWEVENT_RESIZED,
    SDL_WINDOWEVENT_SIZE_CHANGED,
    SDL_WINDOWEVENT_MINIMIZED,
    SDL_WINDOWEVENT_MAXIMIZED,
    SDL_WINDOWEVENT_RESTORED,
    SDL_WINDOWEVENT_ENTER,
    SDL_WINDOWEVENT_LEAVE,
    SDL_WINDOWEVENT_FOCUS_GAINED,
    SDL_WINDOWEVENT_FOCUS_LOST,
    SDL_WINDOWEVENT_CLOSE
} SDL_WindowEventID;

typedef enum
{
    SDL_RENDERER_SOFTWARE = 0x00000001,
    SDL_RENDERER_ACCELERATED = 0x00000002,
    SDL_RENDERER_PRESENTVSYNC = 0x00000004,
    SDL_RENDERER_TARGETTEXTURE = 0x00000008
} SDL_RendererFlags;
typedef struct SDL_RendererInfo
{
    const char *name;
    Uint32 flags;
    Uint32 num_texture_formats;
    Uint32 texture_formats[16];
    int max_texture_width;
    int max_texture_height;
} SDL_RendererInfo;
typedef enum
{
    SDL_TEXTUREACCESS_STATIC,
    SDL_TEXTUREACCESS_STREAMING,
    SDL_TEXTUREACCESS_TARGET
} SDL_TextureAccess;
typedef enum
{
    SDL_TEXTUREMODULATE_NONE = 0x00000000,
    SDL_TEXTUREMODULATE_COLOR = 0x00000001,
    SDL_TEXTUREMODULATE_ALPHA = 0x00000002
} SDL_TextureModulate;
typedef enum
{
    SDL_FLIP_NONE = 0x00000000,
    SDL_FLIP_HORIZONTAL = 0x00000001,
    SDL_FLIP_VERTICAL = 0x00000002
} SDL_RendererFlip;
struct SDL_Renderer;
typedef struct SDL_Renderer SDL_Renderer;
struct SDL_Texture;
typedef struct SDL_Texture SDL_Texture;
int SDL_GetNumRenderDrivers(void);
int SDL_GetRenderDriverInfo(int index, SDL_RendererInfo * info);
int SDL_CreateWindowAndRenderer(int width, int height, Uint32 window_flags, SDL_Window **window, SDL_Renderer **renderer);
SDL_Renderer * SDL_CreateRenderer(SDL_Window * window, int index, Uint32 flags);
SDL_Renderer * SDL_CreateSoftwareRenderer(SDL_Surface * surface);
SDL_Renderer * SDL_GetRenderer(SDL_Window * window);
int SDL_GetRendererInfo(SDL_Renderer * renderer, SDL_RendererInfo * info);
int SDL_GetRendererOutputSize(SDL_Renderer * renderer, int *w, int *h);
SDL_Texture * SDL_CreateTexture(SDL_Renderer * renderer, Uint32 format, int access, int w, int h);
SDL_Texture * SDL_CreateTextureFromSurface(SDL_Renderer * renderer, SDL_Surface * surface);
int SDL_QueryTexture(SDL_Texture * texture,Uint32 * format, int *access,int *w, int *h);
													  
]]
--]]


--[[
typedef struct SDL_WindowEvent
{
    Uint32 type;
    Uint32 timestamp;
    Uint32 windowID;
    Uint8 event;
    Uint8 padding1;
    Uint8 padding2;
    Uint8 padding3;
    Sint32 data1;
    Sint32 data2;
} SDL_WindowEvent;

typedef enum
{
    SDL_WINDOWEVENT_NONE,
    SDL_WINDOWEVENT_SHOWN,
    SDL_WINDOWEVENT_HIDDEN,
    SDL_WINDOWEVENT_EXPOSED,
    SDL_WINDOWEVENT_MOVED,
    SDL_WINDOWEVENT_RESIZED,
    SDL_WINDOWEVENT_SIZE_CHANGED,
    SDL_WINDOWEVENT_MINIMIZED,
    SDL_WINDOWEVENT_MAXIMIZED,
    SDL_WINDOWEVENT_RESTORED,
    SDL_WINDOWEVENT_ENTER,
    SDL_WINDOWEVENT_LEAVE,
    SDL_WINDOWEVENT_FOCUS_GAINED,
    SDL_WINDOWEVENT_FOCUS_LOST,
    SDL_WINDOWEVENT_CLOSE
} SDL_WindowEventID;

typedef union SDL_Event
{
    Uint32 type;
    SDL_CommonEvent common;
    SDL_WindowEvent window;
    SDL_KeyboardEvent key;
    SDL_TextEditingEvent edit;
    SDL_TextInputEvent text;
    SDL_MouseMotionEvent motion;
    SDL_MouseButtonEvent button;
    SDL_MouseWheelEvent wheel;
    SDL_JoyAxisEvent jaxis;
    SDL_JoyBallEvent jball;
    SDL_JoyHatEvent jhat;
    SDL_JoyButtonEvent jbutton;
    SDL_JoyDeviceEvent jdevice;
    SDL_ControllerAxisEvent caxis;
    SDL_ControllerButtonEvent cbutton;
    SDL_ControllerDeviceEvent cdevice;
    SDL_QuitEvent quit;
    SDL_UserEvent user;
    SDL_SysWMEvent syswm;
    SDL_TouchFingerEvent tfinger;
    SDL_MultiGestureEvent mgesture;
    SDL_DollarGestureEvent dgesture;
    SDL_DropEvent drop;
    Uint8 padding[56];
} SDL_Event;

SDL_WINDOW_FULLSCREEN	fullscreen window
SDL_WINDOW_FULLSCREEN_DESKTOP	fullscreen window at the current desktop resolution
SDL_WINDOW_OPENGL	window usable with OpenGL context
SDL_WINDOW_SHOWN	window is visible
SDL_WINDOW_HIDDEN	window is not visible
SDL_WINDOW_BORDERLESS	no window decoration
SDL_WINDOW_RESIZABLE	window can be resized
SDL_WINDOW_MINIMIZED	window is minimized
SDL_WINDOW_MAXIMIZED	window is maximized
SDL_WINDOW_INPUT_GRABBED	window has grabbed input focus
SDL_WINDOW_INPUT_FOCUS	window has input focus
SDL_WINDOW_MOUSE_FOCUS	window has mouse focus
SDL_WINDOW_FOREIGN	window not created by SDL
SDL_WINDOW_ALLOW_HIGHDPI	window should be created in high-DPI mode if supported (>= SDL 2.0.1)
SDL_WINDOW_MOUSE_CAPTURE	window has mouse captured (unrelated to INPUT_GRABBED, >= SDL 2.0.4)
SDL_WINDOW_ALWAYS_ON_TOP	window should always be above others (X11 only, >= SDL 2.0.5)
SDL_WINDOW_SKIP_TASKBAR	window should not be added to the taskbar (X11 only, >= SDL 2.0.5)
SDL_WINDOW_UTILITY	window should be treated as a utility window (X11 only, >= SDL 2.0.5)
SDL_WINDOW_TOOLTIP	window should be treated as a tooltip (X11 only, >= SDL 2.0.5)
SDL_WINDOW_POPUP_MENU	window should be treated as a popup menu (X11 only, >= SDL 2.0.5)

If you store your images in RAM and use the CPU for rendering(this is called software rendering) you use SDL_UpdateWindowSurface.

By calling this function you tell the CPU to update the screen and draw using software rendering.

You can store your textures in RAM by using SDL_Surface, but software rendering is inefficent. You can give draw calls by using SDL_BlitSurface.

SDL_UpdateWindowSurface is equivalent to the SDL 1.2 API SDL_Flip().
On the other side when you use the GPU to render textures and you store your texture on the GPU(this is called hardware accelerated rendering), which you should, you use SDL_RenderPresent.

This function tells the GPU to render to the screen.

You store texture on the GPU using SDL_Texture. When using this you can give draw calls by using SDL_RenderCopy or if you want transformations SDL_RenderCopyEx

Therefore, when using SDL's rendering API, one does all drawing intended for the frame, and then calls this function once per frame to present the final drawing to the user.
You should you use hardware rendering it's far more efficent, than software rendering! Even if the user running the program hasn't got a GPU (which is rare, because most CPU's have an integrated GPU) SDL will switch to software rendering by it self!

By the way you can load an image as SDL_Texture without the need to load an image as an SDL_Surface and convert it to an SDL_Texture using the SDL_image library, which you should because it supports several image formats not just BMP, like pure SDL. (SDL_image is made by the creators of SDL)

Just use the IMG_LoadTexture from SDL_image!

void PrintEvent(const SDL_Event * event)
{
    if (event->type == SDL_WINDOWEVENT) {
        switch (event->window.event) {
        case SDL_WINDOWEVENT_SHOWN:
            SDL_Log("Window %d shown", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_HIDDEN:
            SDL_Log("Window %d hidden", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_EXPOSED:
            SDL_Log("Window %d exposed", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_MOVED:
            SDL_Log("Window %d moved to %d,%d",
                    event->window.windowID, event->window.data1,
                    event->window.data2);
            break;
        case SDL_WINDOWEVENT_RESIZED:
            SDL_Log("Window %d resized to %dx%d",
                    event->window.windowID, event->window.data1,
                    event->window.data2);
            break;
        case SDL_WINDOWEVENT_SIZE_CHANGED:
            SDL_Log("Window %d size changed to %dx%d",
                    event->window.windowID, event->window.data1,
                    event->window.data2);
            break;
        case SDL_WINDOWEVENT_MINIMIZED:
            SDL_Log("Window %d minimized", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_MAXIMIZED:
            SDL_Log("Window %d maximized", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_RESTORED:
            SDL_Log("Window %d restored", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_ENTER:
            SDL_Log("Mouse entered window %d",
                    event->window.windowID);
            break;
        case SDL_WINDOWEVENT_LEAVE:
            SDL_Log("Mouse left window %d", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_FOCUS_GAINED:
            SDL_Log("Window %d gained keyboard focus",
                    event->window.windowID);
            break;
        case SDL_WINDOWEVENT_FOCUS_LOST:
            SDL_Log("Window %d lost keyboard focus",
                    event->window.windowID);
            break;
        case SDL_WINDOWEVENT_CLOSE:
            SDL_Log("Window %d closed", event->window.windowID);
            break;
#if SDL_VERSION_ATLEAST(2, 0, 5)
        case SDL_WINDOWEVENT_TAKE_FOCUS:
            SDL_Log("Window %d is offered a focus", event->window.windowID);
            break;
        case SDL_WINDOWEVENT_HIT_TEST:
            SDL_Log("Window %d has a special hit test", event->window.windowID);
            break;
#endif
        default:
            SDL_Log("Window %d got unknown event %d",
                    event->window.windowID, event->window.event);
            break;
        }
    }
}
--]]
--[[
  --local m=sdl.lowerBlit(image, nil, windowsurface, nil)
 
  --sdl.setRenderDrawColor(rend,100,100,100,55)
  --for i=1,100 do sdl.renderDrawLine(rend,rnd(wndH-1),rnd(wndH-1),rnd(wndH-1),rnd(wndH-1)) end
 -- sdl.lockTexture(texture, nil, &pixels, wndW*4);
  sdl.updateTexture(texture,nil,pix[0],wndW*4)
--sdl.updateTexture(texture,nil,fb2.buf[0],wndW*4)
  --  sdl.unlockTexture(texture)
  --sdl.setRenderTarget(rend, nil)
 sdl.renderCopy(rend, texture, nil, nil);
 -- for i=1,100 do sdl.renderDrawLine(rend,rnd(wndH-1),rnd(wndH-1),rnd(wndH-1),rnd(wndH-1)) end
 -- sdl.renderPresent(rend)
   --sdl.updateWindowSurface(sdlWindow)
   
   local sdl = require 'sdl2'
--local C = ffi.C
sdlWindow=sdl.gL_GetCurrentWindow()
local windowsurface = sdl.getWindowSurface(sdlWindow)
--local image = sdl.loadBMP("lena.bmp")
local image=sdl.createRGBSurface(0,wndW,wndH,32,0,0,0,0)
local pixels=ffi.cast('uint32_t *',image.pixels)
 ffi.cdef[[
  typedef struct { uint8_t r, g, b, a; } rgba_pixel;
  ]]
 --local pixels2=ffi.cast('rgba_pixel *',image.pixels) 
--for i=0,(image.w*image.h)-1 do pixels[i]=0xFFFF0000 end
--sdl.upperBlit(image, nil, windowsurface, nil)
--sdl.upperBlit(image, nil, windowsurface, nil)
--sdl.updateWindowSurface(sdlWindow)
--]]
--[[
local pix={} pix[0]=ffi.cast('rgba_pixel *',windowsurface.pixels) 
--local pix={} pix[0]=pixels2
local pix32={} pix32[0]=pixels
local rnd=math.random
local rol,ror=bit.rol,bit.ror
	for i=1,wndH-1 do
		pix[i]=pix[0]+wndW*i
    pix32[i]=pix32[0]+wndW*i
	end
local sin,cos=math.sin,math.cos
local function fuck(t)
  	for y=wndH-1,wndH/4,-1 do
		for x=wndW-1,wndW/4,-1 do
			pix[y][x].r=(y+10)%255
			pix[y][x].g=(x*y)%255
			pix[y][x].b=((255-y))%255
			pix[y][x].a=255
		end
	end
  for y=0,wndH/4 do local noise=rnd(255)  for x=0,wndW-1 do  -- координаты начинаются с нуля, и кончаются wndW-1 и wndH-1

pix[y][x].r=ror(rol(noise,x*y),lshift(y,x)) 
pix[y][x].g=ror(rol(noise,x*y),lshift(y,x)) 
pix[y][x].b=ror(rol(noise,x*y),lshift(y,x))  
end end
end
local function fuck2()
  for y=0,wndH-1 do for x=0,wndW-1 do pix[y][x].b=80 end end 
end

--sdl.upperBlit(image, nil, windowsurface, nil)
--rend=sdl.getRenderer(sdlWindow)
rend=sdl.createRenderer(sdlWindow,-1,0)
--rend=sdl.createSoftwareRenderer(windowsurface)
texture=sdl.createTexture(rend, sdl.PIXELFORMAT_ARGB8888, sdl.TEXTUREACCESS_STREAMING, wndW, wndH);
--texture=sdl.createTextureFromSurface(rend, image)
w=sdlWindow r=rend
--fuck()
--]]