local nw = require'nw'

local objc = require'objc'
local ffi = require'ffi'
local dispatch = require'objc_dispatch'

objc.load'AVFoundation'
objc.load'CoreVideo'
objc.load'CoreMedia'
objc.load'CoreFoundation'

local B = {}

local session = {}
B.session = session

local VI_AVCaptureVideoDataOutput = objc.class('VI_AVCaptureVideoDataOutput',
	'AVCaptureVideoDataOutput <AVCaptureVideoDataOutputSampleBufferDelegate>')

function session:_init(t)

	local device = objc.AVCaptureDevice:defaultDeviceWithMediaType(objc.AVMediaTypeVideo)
	assert(device)

	local err = ffi.new'id[1]'
	local input = objc.AVCaptureDeviceInput:deviceInputWithDevice_error(device, err)
	assert(err[0] == nil)
	assert(input)

	local output = VI_AVCaptureVideoDataOutput:new()
	assert(output)

	--set bgra8 output
	local pixelformat = objc.tolua(ffi.cast('id', objc.kCVPixelBufferPixelFormatTypeKey))
	local settings = objc.toobj{[pixelformat] = objc.kCVPixelFormatType_32BGRA}
	output:setVideoSettings(settings)

	output:setAlwaysDiscardsLateVideoFrames(true)

	function output.captureOutput_didOutputSampleBuffer_fromConnection(output, _, cmsb, conn)
		if not self.newframe then return end
		local img = objc.CMSampleBufferGetImageBuffer(cmsb)
		objc.CVPixelBufferLockBaseAddress(img, objc.kCVPixelBufferLock_ReadOnly)
		local buf = objc.CVPixelBufferGetBaseAddress(img)
		local sz = objc.CVImageBufferGetDisplaySize(img)
		local w, h = sz.width, sz.height
		local bitmap = {
			data = buf,
			w = w,
			h = h,
			stride = w * 4,
			size   = w * 4 * h,
			format = 'bgra8',
		}
		self:newframe(bitmap)
		objc.CVPixelBufferUnlockBaseAddress(img, objc.kCVPixelBufferLock_ReadOnly)
	end

	local queue = dispatch.main_queue
	output:setSampleBufferDelegate_queue(output, queue)
	dispatch.release(queue)

	local session = objc.AVCaptureSession:alloc():init()
	assert(session)
	session:setSessionPreset(objc.AVCaptureSessionPresetHigh)
	assert(session:canAddInput(input))
	session:addInput(input)
	assert(session:canAddOutput(output))
	session:addOutput(output)

	self.device = device
	self.input = input
	self.output = output
	self.session = session

	return self
end

function session:start()
	self.session:startRunning()
end

function session:stop()
	session:stopRunning()
end

function session:running()
	return self.session.running
end

function session:close()
	self:stop()
end

return B
