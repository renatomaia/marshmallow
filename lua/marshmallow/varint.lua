local string = require "string"
local packsize = string.packsize

local memory = require "memory"
local pack = memory.pack
local unpack = memory.unpack

local intbytes = 0
local packfmt = {}
local maskmsb = 0xfe
local value = 1<<8
while value > 0 do
	intbytes = intbytes+1
	packfmt[intbytes] = "I"..intbytes
	maskmsb = maskmsb<<8
	value = value<<8
end
intbytes = intbytes+1
packfmt[intbytes] = "J"

local varint = { intbytes = intbytes }

do
	local suffix = ""
	local bytes = 0
	value = 0
	repeat
		value = (value-1)>>7
		bytes = bytes+1
		if bytes%intbytes == 0 then
			suffix = suffix..packfmt[intbytes]
			packfmt[bytes] = suffix
		elseif packfmt[bytes] == nil then
			packfmt[bytes] = packfmt[bytes%intbytes]..suffix
		end
	until value == 0

	local function encodeuintvar(stream, pos, value, varint, size, ...)
		local bytes = 1
		value = value>>7
		while value > 0 do
			value = value-1
			local byte = 0x80|value&0x7f
			if bytes == intbytes then
				return encodeuintvar(stream, pos, value, byte, bytes+size, varint, ...)
			end
			varint = varint<<8|byte
			value = value>>7
			bytes = bytes+1
		end
		bytes = bytes+size
		if bytes > #stream then return false, pos end
		return pack(stream, packfmt[bytes], pos, varint, ...)
	end

	function varint.encode(stream, pos, value)
		return encodeuintvar(stream, pos, value, value&0x7f, 0)
	end
end

function varint.decode(stream, pos)
	local byte
	byte, pos = unpack(stream, "B", pos)
	local value = byte&0x7f
	while byte&0x80 ~= 0 do
		value = value+1
		if value == 0 or value&maskmsb ~= 0 then
			error("overflow", 2)
		end
		byte, pos = unpack(stream, "B", pos)
		value = value<<7|byte&0x7f
	end
	return value, pos
end

return varint
