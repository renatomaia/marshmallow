local varint = require "marshmallow.varint"
local memory = require "memory"

local samples = {
	[                    0x0 ] =                                         "\x00",
	[                    0x1 ] =                                         "\x01",
	[                    0x2 ] =                                         "\x02",
	[                    0x3 ] =                                         "\x03",
	[                   0x7f ] =                                         "\x7f",
	[                   0x80 ] =                                     "\x80\x00",
	[                   0xff ] =                                     "\x80\x7f",
	[                 0x407f ] =                                     "\xff\x7f",
	[                 0x4080 ] =                                 "\x80\x80\x00",
	[                 0x7fff ] =                                 "\x80\xfe\x7f",
	[                 0xffff ] =                                 "\x82\xfe\x7f",
	[               0x20407f ] =                                 "\xff\xff\x7f",
	[               0x204080 ] =                             "\x80\x80\x80\x00",
	[             0x1020407f ] =                             "\xff\xff\xff\x7f",
	[             0x10204080 ] =                         "\x80\x80\x80\x80\x00",
	[             0x7fffffff ] =                         "\x86\xfe\xfe\xfe\x7f",
	[             0xffffffff ] =                         "\x8e\xfe\xfe\xfe\x7f",
	[            0x81020407f ] =                         "\xff\xff\xff\xff\x7f",
	[            0x810204080 ] =                     "\x80\x80\x80\x80\x80\x00",
	[          0x4081020407f ] =                     "\xff\xff\xff\xff\xff\x7f",
	[          0x40810204080 ] =                 "\x80\x80\x80\x80\x80\x80\x00",
	[        0x204081020407f ] =                 "\xff\xff\xff\xff\xff\xff\x7f",
	[        0x2040810204080 ] =             "\x80\x80\x80\x80\x80\x80\x80\x00",
	[      0x10204081020407f ] =             "\xff\xff\xff\xff\xff\xff\xff\x7f",
	[      0x102040810204080 ] =         "\x80\x80\x80\x80\x80\x80\x80\x80\x00",
	[     0x7fffffffffffffff ] =         "\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xfe\x7f",
	[     0x8000000000000000 ] =         "\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xff\x00",
	[     0x810204081020407f ] =         "\xff\xff\xff\xff\xff\xff\xff\xff\x7f",
	[     0x8102040810204080 ] =     "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x00",
	[     0xffffffffffffffff ] =     "\x80\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xfe\x7f",
} local overflow = {
	[   "0x10000000000000000"] =     "\x80\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xff\x00",
	[   "0x10000000000000001"] =     "\x80\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xff\x01",
	[   "0x80000000000000000"] =     "\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xff\x00",
	[  "0x40810204081020407f"] =     "\xff\xff\xff\xff\xff\xff\xff\xff\xff\x7f",
	[  "0x408102040810204080"] = "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x00",
	["0x1040810204081020407f"] = "\x80\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xfe\xfe\x7f",
}

print("[varint]")
for number, encoded in pairs(samples) do
	io.write(string.format("- 0x%x ", number))
	io.flush()

	local buffer = memory.create(#encoded-1)
	local ok, pos = varint.pack(buffer, 1, number)
	assert(not ok)
	assert(pos == 1)
	assert(memory.diff(buffer, string.rep("\0", #encoded-1)) == nil)
	io.write("."); io.flush()

	local buffer = memory.create(encoded, 1, -2)
	local ok, errmsg = pcall(varint.unpack, buffer, 1)
	assert(not ok)
	assert(string.find(errmsg, "data string too short", 1, true))
	io.write("."); io.flush()

	local buffer = memory.create(#encoded)
	local ok, pos = varint.pack(buffer, 2, number)
	assert(not ok)
	assert(pos == 2, pos)
	assert(memory.diff(buffer, string.rep("\0", #encoded)) == nil)
	io.write("."); io.flush()

	local ok, pos = varint.pack(buffer, 1, number)
	assert(ok)
	assert(pos == #encoded+1)
	assert(memory.diff(buffer, encoded) == nil)
	io.write("."); io.flush()

	local restored, pos = varint.unpack(buffer, 1)
	assert(restored == number)
	assert(pos == #encoded+1)
	assert(memory.diff(buffer, encoded) == nil)
	io.write("."); io.flush()

	local buffer = memory.create(#encoded+6)
	memory.set(buffer, 1, 1,2,3)
	memory.set(buffer, #encoded+4, 253,254,255)
	local ok, pos = varint.pack(buffer, 4, number)
	assert(ok)
	assert(pos == #encoded+4)
	assert(memory.diff(buffer, "\001\002\003"..encoded.."\253\254\255") == nil)
	io.write("."); io.flush()

	local restored, pos = varint.unpack(buffer, 4)
	assert(restored == number)
	assert(pos == #encoded+4)
	assert(memory.diff(buffer, "\001\002\003"..encoded.."\253\254\255") == nil)
	io.write("."); io.flush()

	print(" OK")
end
for number, encoded in pairs(overflow) do
	io.write(string.format("- %s ", number))
	io.flush()

	local buffer = memory.create(encoded)
	local ok, errmsg = pcall(varint.unpack, buffer, 1)
	assert(not ok)
	assert(errmsg == "overflow")
	io.write("."); io.flush()

	print(" OK")
end
print("Success!")
