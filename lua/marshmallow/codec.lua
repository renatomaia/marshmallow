local memory = require "memory"
local mempack = memory.pack
local memunpack = memory.unpack

local varint = require "marshmallow.varint"
local varintpack = varint.pack
local varintunpack = varint.unpack
local intbytes = varint.intbytes

local bitmax = intbytes*8

local Encoder = {
	__index = false,
	bitcount = 0,
	bitbuffer = 0,
}
Encoder.__index = Encoder

local function packlebits(self, value, size)
	local count = self.bitcount
	local buffer = self.bitbuffer|(value<<count)
	count = count+size
	while count >= bitmax do
		if not self:pack("<J", buffer) then return false end
		count = count-bitmax
		buffer = value>>(size-count)
	end
	self.bitcount = count
	self.bitbuffer = buffer
	return true
end

local function packbebits(self, value, size)
	local count = self.bitcount+size
	local buffer = self.bitbuffer|(value<<(bitmax-count))
	while count >= bitmax do
		if not self:pack(">J", buffer) then return false end
		count = count-bitmax
		buffer = value<<(bitmax-count)
	end
	self.bitcount = count
	self.bitbuffer = buffer
	return true
end

local function updatepack(ok, position)
	if ok then self.position = position end
	return ok
end

function Encoder:align(value)
	-- body
end

function Encoder:uintvar(value)
	return updatepack(self, varintpack(self.output, self.position, value))
end

function Encoder:value(format, ...)
	return updatepack(self, mempack(self.output, format, self.position, ...))
end

--boolean = "B",
--sint8 = "i1",
--sint16 = "i2",
--sint32 = "i4",
--sint64 = "i8",
--uint8 = "I1",
--uint16 = "I2",
--uint32 = "I4",
--uint64 = "I8",
--float32 = "f",
--float64 = "d",
--char = "c1",
--wchar = "c2",



local Decoder = {
	__index = false,
	bitcount = 0,
	bitbuffer = 0,
}
Decoder.__index = Decoder

function Decoder:bits(size)
	-- body
end

function Decoder:align(value)
	-- body
end

function Decoder:uintvar()
	-- body
end

function Decoder:value(format)
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
