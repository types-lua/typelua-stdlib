--- Bounds-checked binary reading and writing.
---
--- All integers are unsigned unless the method name starts with `i`. Byte order
--- is explicit in every multi-byte method. Readers raise on truncation instead
--- of returning partial data; writers validate integer ranges before emitting.
--- The implementation is byte-oriented and portable across Lua 5.1/5.4.

class ByteReader {
  data: string,
  pos: integer = 1,

  constructor(data: string)
    self.data = data
  end,

  position(): integer
    return self.pos
  end,

  remaining(): integer
    if self.pos > #self.data then return 0 end
    return #self.data - self.pos + 1
  end,

  eof(): boolean
    return self.pos > #self.data
  end,

  requireBytes(count: integer): void
    if count < 0 then error("byte count must be >= 0") end
    if self.pos + count - 1 > #self.data then
      error("truncated binary data at byte " .. tostring(self.pos))
    end
  end,

  u8(): integer
    self:requireBytes(1)
    local value: integer = string.byte(self.data, self.pos)!
    self.pos = self.pos + 1
    return value
  end,

  i8(): integer
    local value: integer = self:u8()
    if value >= 128 then return value - 256 end
    return value
  end,

  bytes(count: integer): string
    self:requireBytes(count)
    local value: string = string.sub(self.data, self.pos, self.pos + count - 1)
    self.pos = self.pos + count
    return value
  end,

  peek(count: integer): string
    self:requireBytes(count)
    return string.sub(self.data, self.pos, self.pos + count - 1)
  end,

  skip(count: integer): void
    self:requireBytes(count)
    self.pos = self.pos + count
  end,

  u16le(): integer
    self:requireBytes(2)
    local b1: integer = self:u8()
    local b2: integer = self:u8()
    return b1 + b2 * 256
  end,

  u16be(): integer
    self:requireBytes(2)
    local b1: integer = self:u8()
    local b2: integer = self:u8()
    return b1 * 256 + b2
  end,

  u32le(): integer
    self:requireBytes(4)
    local b1: integer = self:u8()
    local b2: integer = self:u8()
    local b3: integer = self:u8()
    local b4: integer = self:u8()
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
  end,

  u32be(): integer
    self:requireBytes(4)
    local b1: integer = self:u8()
    local b2: integer = self:u8()
    local b3: integer = self:u8()
    local b4: integer = self:u8()
    return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
  end,

  i32le(): integer
    local value: integer = self:u32le()
    if value >= 2147483648 then return value - 4294967296 end
    return value
  end,

  i32be(): integer
    local value: integer = self:u32be()
    if value >= 2147483648 then return value - 4294967296 end
    return value
  end,
}

class ByteWriter {
  parts: string[] = {},
  count: integer = 0,

  constructor() end,

  length(): integer
    return self.count
  end,

  clear(): void
    self.parts = {}
    self.count = 0
  end,

  append(data: string): void
    self.parts[#self.parts + 1] = data
    self.count = self.count + #data
  end,

  bytes(data: string): void
    self:append(data)
  end,

  u8(value: integer): void
    if value < 0 or value > 255 then error("u8 value must be 0..255") end
    self:append(string.char(value))
  end,

  i8(value: integer): void
    if value < -128 or value > 127 then error("i8 value must be -128..127") end
    if value < 0 then value = value + 256 end
    self:append(string.char(value))
  end,

  u16le(value: integer): void
    if value < 0 or value > 65535 then error("u16 value must be 0..65535") end
    self:append(string.char(value % 256, math.floor(value / 256) % 256))
  end,

  u16be(value: integer): void
    if value < 0 or value > 65535 then error("u16 value must be 0..65535") end
    self:append(string.char(math.floor(value / 256) % 256, value % 256))
  end,

  u32le(value: number): void
    if value < 0 or value > 4294967295 or math.floor(value) ~= value then
      error("u32 value must be an integer in 0..4294967295")
    end
    local v: integer = math.floor(value)
    self:append(string.char(
      v % 256,
      math.floor(v / 256) % 256,
      math.floor(v / 65536) % 256,
      math.floor(v / 16777216) % 256
    ))
  end,

  u32be(value: number): void
    if value < 0 or value > 4294967295 or math.floor(value) ~= value then
      error("u32 value must be an integer in 0..4294967295")
    end
    local v: integer = math.floor(value)
    self:append(string.char(
      math.floor(v / 16777216) % 256,
      math.floor(v / 65536) % 256,
      math.floor(v / 256) % 256,
      v % 256
    ))
  end,

  i32le(value: integer): void
    if value < -2147483648 or value > 2147483647 then
      error("i32 value must be in -2147483648..2147483647")
    end
    local unsigned: number = value
    if unsigned < 0 then unsigned = unsigned + 4294967296 end
    self:u32le(unsigned)
  end,

  i32be(value: integer): void
    if value < -2147483648 or value > 2147483647 then
      error("i32 value must be in -2147483648..2147483647")
    end
    local unsigned: number = value
    if unsigned < 0 then unsigned = unsigned + 4294967296 end
    self:u32be(unsigned)
  end,

  toString(): string
    return table.concat(self.parts)
  end,
}

return {
  ByteReader = ByteReader,
  ByteWriter = ByteWriter,
}
