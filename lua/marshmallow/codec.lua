local varint = require "marshmallow.varint"
local intbytes = varint.intbytes

local bitmaxcount = intbytes*8

local Encoder = {
	__index = false,
	bitcount = 0,
	bitbuffer = 0,
}
Encoder.__index = Encoder

function Encoder:bits(size, value)
	local count = self.bitcount
	local buffer = self.bitbuffer|(value<<count)
	count = count+size
	while count >= bitmaxcount do
		self.stream:pack("J", buffer)
		count = count-bitmaxcount
		buffer = value>>(size-count)
	end
	self.bitcount = count
	self.bitbuffer = buffer
end

function Encoder:align(value)
	-- body
end

function Encoder:uintvar(value)
	-- body
end

function Encoder:pack(value)
	-- body
end

local Decoder = {
	__index = false,
	bitcount = 0,
}
Decoder.__index = Decoder

function Decoder:bits(size, value)
	-- body
end

function Decoder:align(value)
	-- body
end

function Decoder:uintvar(value)
	-- body
end

function Decoder:pack(value)
	-- body
end

local codec = {}

function codec.encoder(stream)
	return setmetatable({ stream = stream }, Encoder)
end

function codec.decoder(stream)
	return setmetatable({ stream = stream }, Decoder)
end

return codec

--[[
BE: 0XXX 0000 offset=1;partial=4;shift=4
LE: 0000 XXX0 offset=1;partial=4;shift=1

BE: 0000 00XX  XXX0 0000 offset=6;partial=3;shift=5
LE: 0000 0XXX  XX00 0000 offset=6;partial=3;shift=6
--]]
