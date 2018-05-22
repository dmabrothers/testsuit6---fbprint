
if not love then
local wrap=1
	love={'nanolove.lua','nanolove_blit.lua'}
	local t={window={},modules={}}
	dofile  'conf.lua'  
	if love.conf then love.conf(t) end
	nanolove=1
	dofile (love[wrap]) (t.window.width,t.window.height,'main2')
else
require 'main2'
end