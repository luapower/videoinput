
local ffi = require'ffi'
local glue = require'glue'

local M = {}

local backends = {
	osx = 'videoinput_cocoa',
	linux = 'videoinput_v4l',
	windows = 'videoinput_dshow',
}

local B = require(assert(backends[ffi.os:lower()], 'OS not supported'))

function M.devices(which)
	if which == '#' then --count
		return B.device_count()
	elseif which == '*' then --default
		return B.default_device()
	else --iterate
		return B.devices()
	end
end

local session = {}

function M.open(t)
	local self = glue.update({}, B.session, session)
	self:_init(t)
	return self
end


return M

