-- [0x70..0x7e]
local tags = {
	-- standard
	TUPLE    = 0x70, -- 'p'
	BIT      = 0x71, -- 'q'
	TYPEREF  = 0x72, -- 'r'
	SPAN     = 0x73, -- 's'
	TYPE     = 0x74, -- 't'
	UNION    = 0x75, -- 'u'
	VOID     = 0x76, -- 'v'
	OBJECT   = 0x77, -- 'w'
	ALIGN    = 0x78, -- 'x'
	LIST     = 0x79, -- 'y'
	ARRAY    = 0x7a, -- 'z'
	BUNDLE   = 0x7b, -- '{'
	CHOICE   = 0x7c, -- '|'
	DYNAMIC  = 0x7d, -- '}'
	EMBEDDED = 0x7e, -- '~'
	-- custom aliases
	UINT     = 0x0a,
	SINT     = 0x1a,
	UINTVAR  = 0x2a,
	SINTVAR  = 0x3a,
	BOOLEAN  = 0x0b,
	BITPAD   = 0x1b,
	--       = 0x2b,
	--       = 0x3b,
	NULL     = 0x0c,
	CHAR     = 0x1c,
	WCHAR    = 0x2c,
	PADDING  = 0x3c,
}

do
	-- [0x00..0x3f]
	local aliases = {
		UINT     = 0x00,
		SINT     = 0x01,
		STREAM   = 0x02,
		STRING   = 0x03,
		WSTRING  = 0x04,
		UNION    = 0x05,
		MAP      = 0x06,
		SET      = 0x07,
		ALIGN    = 0x08,
		LIST     = 0x09,
		--custom = 0x0a,
		--custom = 0x0b,
		--custom = 0x0c,
		--       = 0x0d,
		EMBEDDED = 0x0e,
		FLOAT    = 0x0f,
	}
	local suffixfactor = {
		ALIGN = 1,
		FLOAT = 16,
	}
	for name, value in pairs(aliases) do
		local factor = suffixfactor[name] or 8
		for i = 0, 3 do
			local suffix = (1<<i)*factor
			assert(tags[name..suffix] == nil)
			tags[name..suffix] = (i<<4)+value
		end
	end

	tags.FLOAT256 = 0x4f
end

--[[
do
	local report = {}
	local names = {}
	for name, value in pairs(tags) do
		if names[value] ~= nil then
			error(string.format("%02x %s %s", value, names[value], name))
		end
		names[value] = name
		table.insert(report, string.format("%-12s = %02x", name, value))
	end
	table.sort(report)
	for _, line in ipairs(report) do
		print(line)
	end
end
--]]

--[[
	-- Primitives
	VOID     = 0x00,
	BIT      = 0x01,
	ALIGN    = 0x03, --v:UINTVAR                                                                       := { PAD n | n=(v-index%v) }
	-- Homogeneus compositions
	SPAN     = 0x0e, --t:TYPE                                                                := n:(UINT s) { e[i]:t | 0<i<=n }
	LIST     = 0x0e, --s:UINTVAR t:TYPE                                                                := n:(UINT s) { e[i]:t | 0<i<=n }
	ARRAY    = 0x0b, --n:UINTVAR t:TYPE                                                                := { e[i]:t | 0<i<=n }
	-- Heterogeneous compositions
	TUPLE    = 0x0c, --n:UINTVAR { t[i]:TYPE | 0<i<=n }                                                := { e[1]:t[1]...e[n]:t[n] }
	BUNDLE   = 0x0d, --n:UINTVAR { t[i]:TYPE | 0<i<=n & t[i]<=t[i+1] }                                 := { e[1]:t[1]...e[n]:t[n] }
	UNION    = 0x0d, --s:UINTVAR n:UINTVAR { t[i]:TYPE | 0<i<=n & t[i]<=t[i+1] }                        := i:(UINT s) v:t[i]
	-- Embedded compositions
	SWITCH   = 0x0d, --typeref:UINTVAR n:UINTVAR { k[i]:UINTVAR | 0<i<=n } { t[i]:TYPE | 0<i<=n } d:TYPE := { v:t[i] | k[i]=x:TYPE@typeref }
	-- Modifiers
	OBJECT   = 0x12, --t:TYPE                                                                         := offset:UINTVAR SWITCH 0x00 0x01 0x00 t VOID
	EMBEDDED = 0x13, --s:UINTVAR t:TYPE                                                                := n:(UINT s) { t | length(t)=n }
	-- Predefined: implict ALIGN 0x08
	UINTVAR  = 0x02, -- AS_UNSIGNED TUPLE 0x03 BIT (ARRAY 0x07 BIT) SWITCH 0x03 0x01 0x00 VOID TYPEREF 0x0a
	SINTVAR  = 0x03, -- AS_SIGNED TUPLE 0x03 BIT (ARRAY 0x07 BIT) SWITCH 0x03 0x01 0x00 VOID TYPEREF 0x0a
	TYPE     = 0x06, -- := 
	TYPEREF  = 0x07, -- 
	DYNAMIC  = 0x08, -- 

	--Alignments
	ALIGN1   = 0x17, -- ALIGN 0x08
	ALIGN2   = 0x18, -- ALIGN 0x10
	ALIGN4   = 0x19, -- ALIGN 0x20
	ALIGN8   = 0x1a, -- ALIGN 0x40
	--Sub-Byte
	SINT     = 0x0a, -- AS_SIGNED ARRAY size BIT size
	UINT     = 0x0a, -- AS_UNSIGNED ARRAY size BIT size
	--Common
	NULL     = 0x01, -- AS_NULL VOID
	PAD      = 0x02, -- AS_VOID BIT size
	--Boleans
	BOOLEAN  = 0x1b, -- AS_BOOLEAN ALIGN1 ARRAY 0x08 BIT
	-- Signed Integers (Two's Complement)
	SINT8    = 0x20, -- ALIGN1 SINT 0x08
	SINT16   = 0x21, -- ALIGN1 SINT 0x10
	SINT32   = 0x22, -- ALIGN1 SINT 0x20
	SINT64   = 0x23, -- ALIGN1 SINT 0x40
	-- Unsigned Integers
	UINT8    = 0x1c, -- ALIGN1 UINT 0x08
	UINT16   = 0x1d, -- ALIGN1 UINT 0x10
	UINT32   = 0x1e, -- ALIGN1 UINT 0x20
	UINT64   = 0x1f, -- ALIGN1 UINT 0x40
	-- Floating Point (IEEE 754)
	FLOAT16  = 0x24, -- AS_IEEE754 ALIGN1 TUPLE 0x03 BIT ARRAY 0x05 BIT ARRAY 0x0a BIT
	FLOAT32  = 0x25, -- AS_IEEE754 ALIGN1 TUPLE 0x03 BIT ARRAY 0x08 BIT ARRAY 0x17 BIT
	FLOAT64  = 0x26, -- AS_IEEE754 ALIGN1 TUPLE 0x03 BIT ARRAY 0x0b BIT ARRAY 0x34 BIT
	FLOAT128 = 0x27, -- AS_IEEE754 ALIGN1 TUPLE 0x03 BIT ARRAY 0x0f BIT ARRAY 0x70 BIT
	FLOAT256 = 0x27, -- AS_IEEE754 ALIGN1 TUPLE 0x03 BIT ARRAY 0x13 BIT ARRAY 0xec BIT
	-- Characters
	CHAR     = 0x04, -- AS_ISO8859_1 ALIGN1 ARRAY 0x08 BIT 0x05 BIT
	WCHAR    = 0x05, -- AS_UTF16 ALIGN1 ARRAY 0x10 BIT
	STRING   = 0x29, -- SEMANTIC "nullterm" TUPLE 0x02 LIST size CHAR CHAR
	WSTRING  = 0x2a, -- SEMANTIC "nullterm" TUPLE 0x02 LIST size WCHAR WCHAR
	-- Compositions
	STREAM   = 0x28, -- LIST size UINT8
	SET      = 0x0f, -- AS_SET LIST size type
	MAP      = 0x10, -- AS_MAP LIST size TUPLE 0x02 key value
	-- Semantic (>0x7f)
	AS_VOID      = 0x80,
	AS_NULL      = 0x81,
	AS_BOOLEAN   = 0x82,
	AS_SIGNED    = 0x83,
	AS_UNSIGNED  = 0x84,
	AS_IEEE754   = 0x85,
	AS_ISO8859_1 = 0x86,
}

local temp = {}
for name, code in pairs(tags) do
	temp[code] = name
end
for code, name in pairs(temp) do
	tags[code] = name
end
--]]

return tags
