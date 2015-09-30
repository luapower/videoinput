
local nw = require'nw'
local vi = require'videoinput'
local bitmap = require'bitmap'
local box2d = require'box2d'

local app = nw:app()
local win = app:window{cw = 700, ch = 500}

local session = vi.open{}

function session:newframe(bmp)
	self._bitmap = bitmap.copy(bmp)
	win:invalidate()
end

function session:lastframe()
	return self._bitmap
end

function win:repaint()
	local src = session:lastframe()
	if not src then return end
	local dst = self:bitmap()
	dst:clear()
	bitmap.paint(src, dst, 10, 10)
end

session:start()

app:run()
