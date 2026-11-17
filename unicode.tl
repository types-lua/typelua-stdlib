--- Strict UTF-8 validation, decoding and encoding.
---
--- Unlike Lua's optional `utf8` library, this module is available on Lua 5.1
--- too and rejects overlong forms, UTF-16 surrogate code points, truncated
--- sequences and code points above U+10FFFF. It is intentionally byte-string
--- based so it composes with the rest of this package.

type Utf8DecodeResult = {
  ok: boolean,
  codepoints: integer[],
  error: string,
}

type Utf8EncodeResult = {
  ok: boolean,
  text: string,
  error: string,
}

type Utf8LengthResult = {
  ok: boolean,
  length: integer,
  error: string,
}

type Utf8CodepointResult = {
  ok: boolean,
  codepoint: integer,
  error: string,
}

local function isContinuation(byte: integer): boolean
  return byte >= 0x80 and byte <= 0xBF
end

local function decodeOne(data: string, at: integer): (integer, integer, string)
  local byte: integer = string.byte(data, at)!
  if byte <= 0x7F then
    return byte, 1, ""
  elseif byte >= 0xC2 and byte <= 0xDF then
    if at + 1 > #data then return 0, 0, "truncated 2-byte sequence" end
    local b2: integer = string.byte(data, at + 1)!
    if not isContinuation(b2) then return 0, 0, "invalid 2-byte continuation" end
    return (byte - 0xC0) * 64 + (b2 - 0x80), 2, ""
  elseif byte >= 0xE0 and byte <= 0xEF then
    if at + 2 > #data then return 0, 0, "truncated 3-byte sequence" end
    local b2: integer = string.byte(data, at + 1)!
    local b3: integer = string.byte(data, at + 2)!
    if not isContinuation(b3) then return 0, 0, "invalid 3-byte continuation" end
    if byte == 0xE0 then
      if b2 < 0xA0 or b2 > 0xBF then return 0, 0, "overlong 3-byte sequence" end
    elseif byte == 0xED then
      if b2 < 0x80 or b2 > 0x9F then return 0, 0, "UTF-16 surrogate" end
    elseif b2 < 0x80 or b2 > 0xBF then
      return 0, 0, "invalid 3-byte continuation"
    end
    return math.floor((byte - 0xE0) * 4096 + (b2 - 0x80) * 64 + (b3 - 0x80)), 3, ""
  elseif byte >= 0xF0 and byte <= 0xF4 then
    if at + 3 > #data then return 0, 0, "truncated 4-byte sequence" end
    local b2: integer = string.byte(data, at + 1)!
    local b3: integer = string.byte(data, at + 2)!
    local b4: integer = string.byte(data, at + 3)!
    if not isContinuation(b3) or not isContinuation(b4) then
      return 0, 0, "invalid 4-byte continuation"
    end
    if byte == 0xF0 then
      if b2 < 0x90 or b2 > 0xBF then return 0, 0, "overlong 4-byte sequence" end
    elseif byte == 0xF4 then
      if b2 < 0x80 or b2 > 0x8F then return 0, 0, "code point above U+10FFFF" end
    elseif b2 < 0x80 or b2 > 0xBF then
      return 0, 0, "invalid 4-byte continuation"
    end
    local codepoint: integer = (byte - 0xF0) * 262144
      + (b2 - 0x80) * 4096 + (b3 - 0x80) * 64 + (b4 - 0x80)
    return codepoint, 4, ""
  end
  return 0, 0, "invalid UTF-8 lead byte"
end

local function decode(data: string): Utf8DecodeResult
  local codepoints: integer[] = {}
  local at: integer = 1
  while at <= #data do
    local codepoint, width, err = decodeOne(data, at)
    if err ~= "" then
      return { ok = false, codepoints = codepoints, error = err }
    end
    codepoints[#codepoints + 1] = codepoint
    at = at + width
  end
  return { ok = true, codepoints = codepoints, error = "" }
end

local function valid(data: string): boolean
  local at: integer = 1
  while at <= #data do
    local _codepoint, width, err = decodeOne(data, at)
    if err ~= "" then return false end
    at = at + width
  end
  return true
end

local function encodeCodepoint(codepoint: integer): string
  if codepoint < 0 or codepoint > 0x10FFFF
    or (codepoint >= 0xD800 and codepoint <= 0xDFFF) then
    error("invalid Unicode code point")
  end
  if codepoint <= 0x7F then
    return string.char(codepoint)
  elseif codepoint <= 0x7FF then
    return string.char(
      0xC0 + math.floor(codepoint / 64),
      0x80 + codepoint % 64
    )
  elseif codepoint <= 0xFFFF then
    return string.char(
      0xE0 + math.floor(codepoint / 4096),
      0x80 + math.floor(codepoint / 64) % 64,
      0x80 + codepoint % 64
    )
  end
  return string.char(
    0xF0 + math.floor(codepoint / 262144),
    0x80 + math.floor(codepoint / 4096) % 64,
    0x80 + math.floor(codepoint / 64) % 64,
    0x80 + codepoint % 64
  )
end

local function encode(codepoints: integer[]): Utf8EncodeResult
  local out: string[] = {}
  for i: integer = 1, #codepoints do
    local codepoint: integer = codepoints[i]
    if codepoint < 0 or codepoint > 0x10FFFF
      or (codepoint >= 0xD800 and codepoint <= 0xDFFF) then
      return { ok = false, text = "", error = "invalid Unicode code point" }
    end
    out[#out + 1] = encodeCodepoint(codepoint)
  end
  return { ok = true, text = table.concat(out), error = "" }
end

local function char(codepoint: integer): string
  return encodeCodepoint(codepoint)
end

local function length(data: string): Utf8LengthResult
  local count: integer = 0
  local at: integer = 1
  while at <= #data do
    local _codepoint, width, err = decodeOne(data, at)
    if err ~= "" then
      return { ok = false, length = count, error = err }
    end
    count = count + 1
    at = at + width
  end
  return { ok = true, length = count, error = "" }
end

local function codepointAt(data: string, bytePosition: integer): Utf8CodepointResult
  if bytePosition < 1 or bytePosition > #data then
    return { ok = false, codepoint = 0, error = "byte position out of range" }
  end
  local codepoint, _width, err = decodeOne(data, bytePosition)
  if err ~= "" then return { ok = false, codepoint = 0, error = err } end
  return { ok = true, codepoint = codepoint, error = "" }
end

return {
  valid = valid,
  decode = decode,
  encode = encode,
  char = char,
  length = length,
  count = length,
  codepointAt = codepointAt,
}
