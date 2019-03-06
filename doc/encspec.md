Encoding Specification
======================

Values are encoded according to a specific _type_, which describes the serial data structure used to encode the value, and optionally the semantics as to how interpret the encoded data.
Some fundamental _types_ are predefined and can be combined to create new ones.
Finally, _types_ themselves can be encoded together with the value.

Notation
--------

Encoding
--------

### Tags

Types are described using a _tag_, which is a non-negative integer encoded using a [Variable-Length Quantity (VLQ)](https://en.wikipedia.org/wiki/Variable-length_quantity) encoding, as described in section [UINTVAR](#uintvar).
Depending on the _tag_, other _tags_ or values might follow to further describe the _type_.

```
{uintvar} [...]
```

### Primitives

In the following sections we describe the primitive _types_, which are combined with composition tags to create new types.

#### VOID (`0x76 == 'v'`)

This _type_ indicates that no data is encoded.
This _type_ can be used to describe data that has only one possible value, like `nil` in Lua.

##### Examples

###### Encoding Lua's `nil` as `VOID`.
```
Value: nil
Data : 
```

#### BIT (`0x71 == 'q'`)

This _type_ indicates that only a single bit is used for encoding, leaving previous or following bits unused for other encodings.
This _type_ can be used to describe data that can only have two possible values, like `boolean` in Lua, or a bit flag in a integer field of a C structure.

##### Examples

###### Encoding a `number` as `BIT`.

```
Value: 0
Data : 00

Value: 1
Data : 80
```

###### Encoding three `number`s as `BIT BIT BIT`.

```
Value: 1, 0, 1
Data : a0
```

### Composition

#### ARRAY (0x7a == 'z')

##### Examples

###### Encoding Lua's `{ 1, 0, 1, 1, 0 }` as `LIST 0x00 BIT`.
```
Value: 1, 0, 1, 1, 0
Data : 05 b0
```

#### LIST (0x79 == 'y')
#### LIST8 (0x09)
#### LIST16 (0x19)
#### LIST32 (0x29)
#### LIST64 (0x39)
#### SPAN (0x73 == 's')
#### TUPLE (0x70 == 'p')
#### BUNDLE (0x7b == '{')
#### UNION (0x75 == 'u')
#### UNION8 (0x05)
#### UNION16 (0x15)
#### UNION32 (0x25)
#### UNION64 (0x35)
#### CHOICE (0x7c == '|')

### Aliases

#### UINTVAR

This _type_ indicates that an unsigned integer is encoded like [Git's _varint_](https://github.com/git/git/blob/7fb6aefd2aaffe66e614f7f7b83e5b7ab16d4806/varint.c#L4).
Therefore values smaller than 128 are encoded in a single byte, increasingly larger values occupy more bytes.

##### Examples

###### Encoding non-negative integers as `UINTVAR`.
```
Value: 5
Data : 05

Value: 127
Data : 7f

Value: 128
Data : 80 00

Value: 16511
Data : ff 7f

Value: 16512
Data : 80 80 00

Value: 2113663
Data : ff ff 7f
```

#### SINTVAR
#### TYPE
#### DYNAMIC
#### LIST

```
LIST {uintvar} {type}
```

##### Examples

- Unsigned _varint_'s as `LIST 0x10 UINTVAR`
```
Value: 0xab, 0xcd, 0xef
Data : 00 03 ab cd    ef
```

### ARRAY
### TUPLE
### BUNDLE
### UNION

### SPAN

```
SPAN type
```

Type : SPAN UINTVAR
Value: { 0, 1, 2, 3 }
Bytes: 0x00 0x01 0x02 0x03

### SWITCH

### ALIGN
### OBJECT
### EMBEDDED
### TYPEREF















## Tags

### Semantic

ALIGN        = 78 'x'
  ALIGN1     = 08
  ALIGN2     = 18
  ALIGN4     = 28
  ALIGN8     = 38
OBJECT       = 77 'w'
EMBEDDED     = 7e '~'
  EMBEDDED8  = 0e
  EMBEDDED16 = 1e
  EMBEDDED32 = 2e
  EMBEDDED64 = 3e
TYPE         = 74 't'
TYPEREF      = 72 'r'
DYNAMIC      = 7d '}'

### Aliases

NULL         = 0c
BITPAD       = 1b
PADDING      = 3c
BOOLEAN      = 0b
CHAR         = 1c
WCHAR        = 2c
UINT         = 0a
  UINTVAR    = 2a
  UINT8      = 00
  UINT16     = 10
  UINT32     = 20
  UINT64     = 30
SINT         = 1a
  SINTVAR    = 3a
  SINT8      = 01
  SINT16     = 11
  SINT32     = 21
  SINT64     = 31

FLOAT16      = 0f
FLOAT32      = 1f
FLOAT64      = 2f
FLOAT128     = 3f
FLOAT256     = 4f

STREAM8      = 02
STREAM16     = 12
STREAM32     = 22
STREAM64     = 32

STRING8      = 03
STRING16     = 13
STRING32     = 23
STRING64     = 33

WSTRING8     = 04
WSTRING16    = 14
WSTRING32    = 24
WSTRING64    = 34

SET8         = 07
SET16        = 17
SET32        = 27
SET64        = 37

MAP8         = 06
MAP16        = 16
MAP32        = 26
MAP64        = 36

















Data Encoding
-------------



Every application value is encoded according to a specific _type_, which defines a serial data structure to be used to encode the value.
The _meta encoding_ refers to the rules to describe in serial form a _type_.



This specification can be separated in to parts:
- **Data encoding**: how to encode data according to a defined serial data structure.
- **Meta encoding**: how to encode a complete description of a serial data structure so that it can be transmitted with the data encoded using it.


The _meta encoding_ is composed of _tags_, which are numeric values describing a _type_.
Ideally each possible serial data structure should have a unique encoding.
This is useful for two reasons:
- Make it easy to check if two encoded values are structurally equivalent and can be treated as the same or converted from one to another.
- Be able to dynamically generate optimized encoding implementation for each new _type_ found, and reuse it for other structurally compatible types.

In the remaining of this text we will describe each 'metadata' tag defined and how the 'structural' data (serial data structure) it describes is encoded and should be interpreted.



The encoding can be separated in two basic kinds: _structural_ and _metadata_. The 'structural' encoding is basically an application value encoded using a set of basic serial data structures. The 'metadata' encoding is a representation or language for description of these serial data structures used for 'structural' encoding and also the semantic or meaning of the encoded value. The 'metadata' encoding is commonly referred as the type information of the encoded data.

The 'metadata' encoding is basically composed of special tags, which are numeric values describing a serial data structure, which can be primitive or a serial composition of other serial data strcutures. Ideally each possible serial data structure should have a unique 'metadata' representation. This can be useful for two reasons:

    Make it easy to check if two encoded values are structurally equivalent and can be treated as the same or automatically converted from one to another.

    Be able to dynamically generate optimized encoding implementation for each new type (metadata) found, and reuse it for other structurally compatible types.

In the remaining of this text we will describe each 'metadata' tag defined and how the 'structural' data (serial data structure) it describes is encoded and should be interpreted.


