import T from "tlua_test"
import binary from "../binary"

return {
  ["integer round-trip and endianness"] = function(): void
    local writer = binary.ByteWriter.new()
    writer:u8(255)
    writer:i8(-1)
    writer:u16le(0x1234)
    writer:u16be(0x1234)
    writer:u32le(0x12345678)
    writer:u32be(0x12345678)
    writer:i32le(-2)
    writer:i32be(-2)
    T.eq(writer:length(), 1 + 1 + 2 + 2 + 4 + 4 + 4 + 4, "writer length")
    local wire: string = writer:toString()
    local reader = binary.ByteReader.new(wire)
    T.eq(reader:u8(), 255, "u8")
    T.eq(reader:i8(), -1, "i8")
    T.eq(reader:u16le(), 0x1234, "u16le")
    T.eq(reader:u16be(), 0x1234, "u16be")
    T.eq(reader:u32le(), 0x12345678, "u32le")
    T.eq(reader:u32be(), 0x12345678, "u32be")
    T.eq(reader:i32le(), -2, "i32le")
    T.eq(reader:i32be(), -2, "i32be")
    T.ok(reader:eof(), "eof")
    T.eq(reader:remaining(), 0, "remaining")
  end,

  ["byte order bytes"] = function(): void
    local w = binary.ByteWriter.new()
    w:u16le(0x1234)
    w:u16be(0x1234)
    w:u32le(0x12345678)
    w:u32be(0x12345678)
    T.eq(w:toString(), "\52\18\18\52\120\86\52\18\18\52\86\120", "wire bytes")
  end,

  ["position, peek, bytes and skip"] = function(): void
    local r = binary.ByteReader.new("abcdef")
    T.eq(r:position(), 1, "position start")
    T.eq(r:peek(3), "abc", "peek")
    T.eq(r:position(), 1, "peek does not advance")
    T.eq(r:bytes(2), "ab", "bytes")
    T.eq(r:position(), 3, "position")
    r:skip(2)
    T.eq(r:position(), 5, "skip")
    T.eq(r:remaining(), 2, "remaining")
    T.eq(r:bytes(2), "ef", "tail")
    T.ok(r:eof(), "eof")
    T.eq(r:bytes(0), "", "zero bytes")
  end,

  ["truncation and bounds"] = function(): void
    local r = binary.ByteReader.new("a")
    local positionBefore: integer = r:position()
    T.raises(function(): void r:u16le() end)
    T.eq(r:position(), positionBefore, "truncated u16 does not advance")
    T.raises(function(): void r:bytes(2) end)
    T.raises(function(): void r:skip(2) end)
    T.raises(function(): void r:peek(2) end)
    T.raises(function(): void r:bytes(-1) end)
  end,

  ["writer validation and clear"] = function(): void
    local w = binary.ByteWriter.new()
    T.raises(function(): void w:u8(256) end)
    T.raises(function(): void w:u8(-1) end)
    T.raises(function(): void w:i8(128) end)
    T.raises(function(): void w:u16le(65536) end)
    T.raises(function(): void w:u32le(4294967296) end)
    T.raises(function(): void w:u32le(1.5) end)
    T.raises(function(): void w:i32le(2147483648) end)
    w:u8(1)
    w:u8(2)
    T.eq(w:length(), 2, "length")
    w:clear()
    T.eq(w:length(), 0, "clear length")
    T.eq(w:toString(), "", "clear data")
  end,
}
