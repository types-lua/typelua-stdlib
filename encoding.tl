--- Encoding and decoding helpers: Base64, Base64URL, hex and percent encoding.
---
--- Decoders are strict and return `DecodeResult` instead of quietly skipping
--- malformed input. Encoders take and return byte strings; UTF-8 passes through
--- unchanged.

type DecodeResult = {
  ok: boolean,
  data: string,
  error: string,
}

local BASE64: string = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local BASE32: string = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
local BASE64URL: string = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local HEX_LOWER: string = "0123456789abcdef"
local HEX_UPPER: string = "0123456789ABCDEF"

local function success(data: string): DecodeResult
  return { ok = true, data = data, error = "" }
end

local function failure(message: string): DecodeResult
  return { ok = false, data = "", error = message }
end

local function valueIn(alphabet: string, byte: integer): integer
  if byte >= 65 and byte <= 90 then return byte - 65 end
  if byte >= 97 and byte <= 122 then return byte - 71 end
  if byte >= 48 and byte <= 57 then return byte + 4 end
  if byte == 43 and alphabet == BASE64 then return 62 end
  if byte == 47 and alphabet == BASE64 then return 63 end
  if byte == 45 and alphabet == BASE64URL then return 62 end
  if byte == 95 and alphabet == BASE64URL then return 63 end
  return -1
end

local function base64EncodeWith(data: string, alphabet: string, padding: boolean): string
  local out: string[] = {}
  local i: integer = 1
  while i <= #data do
    local b1: integer = string.byte(data, i)!
    local b2: integer = 0
    local b3: integer = 0
    local have2: boolean = i + 1 <= #data
    local have3: boolean = i + 2 <= #data
    if have2 then b2 = string.byte(data, i + 1)! end
    if have3 then b3 = string.byte(data, i + 2)! end
    local value: integer = b1 * 65536 + b2 * 256 + b3
    local c1: integer = math.floor((value / 262144) % 64)
    local c2: integer = math.floor((value / 4096) % 64)
    local c3: integer = math.floor((value / 64) % 64)
    local c4: integer = math.floor(value % 64)
    out[#out + 1] = string.sub(alphabet, c1 + 1, c1 + 1)
    out[#out + 1] = string.sub(alphabet, c2 + 1, c2 + 1)
    if have2 then
      out[#out + 1] = string.sub(alphabet, c3 + 1, c3 + 1)
    elseif padding then
      out[#out + 1] = "="
    end
    if have3 then
      out[#out + 1] = string.sub(alphabet, c4 + 1, c4 + 1)
    elseif padding then
      out[#out + 1] = "="
    end
    i = i + 3
  end
  return table.concat(out)
end

local function base64DecodeWith(text: string, alphabet: string, allowPadding: boolean): DecodeResult
  if text == "" then return success("") end
  local body: string = text
  local pad: integer = 0
  if allowPadding then
    while #body > 0 and string.sub(body, -1) == "=" do
      pad = pad + 1
      body = string.sub(body, 1, -2)
    end
    if pad > 2 then return failure("invalid Base64 padding") end
    if string.find(body, "=") ~= nil then
      return failure("invalid Base64 padding")
    end
  elseif string.find(body, "=") ~= nil then
    return failure("Base64URL must not contain padding")
  end
  if #body % 4 == 1 then return failure("invalid Base64 length") end
  local expectedPad: integer = (4 - (#body % 4)) % 4
  if allowPadding and pad ~= 0 and pad ~= expectedPad then
    return failure("invalid Base64 padding")
  end
  if not allowPadding and expectedPad ~= 0 then
    -- Unpadded URL alphabet: length 2 or 3 is valid.
  end
  while #body % 4 ~= 0 do
    body = body .. "="
  end

  local out: string[] = {}
  local i: integer = 1
  while i <= #body do
    local chunk: string = string.sub(body, i, i + 3)
    local c1: integer = valueIn(alphabet, string.byte(chunk, 1)!)
    local c2: integer = valueIn(alphabet, string.byte(chunk, 2)!)
    local c3: integer = 0
    local c4: integer = 0
    local chunkPad: integer = 0
    if string.sub(chunk, 3, 3) == "=" then
      chunkPad = 2
    elseif string.sub(chunk, 4, 4) == "=" then
      chunkPad = 1
    else
      c3 = valueIn(alphabet, string.byte(chunk, 3)!)
      c4 = valueIn(alphabet, string.byte(chunk, 4)!)
    end
    if chunkPad == 2 then
      c3 = 0
      c4 = 0
    elseif chunkPad == 1 then
      c3 = valueIn(alphabet, string.byte(chunk, 3)!)
      c4 = 0
    end
    if c1 < 0 or c2 < 0 or (chunkPad < 2 and c3 < 0) or (chunkPad < 1 and c4 < 0) then
      return failure("invalid Base64 character")
    end
    if chunkPad == 2 and c2 % 16 ~= 0 then
      return failure("non-canonical Base64 trailing bits")
    end
    if chunkPad == 1 and c3 % 4 ~= 0 then
      return failure("non-canonical Base64 trailing bits")
    end
    local value: integer = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
    out[#out + 1] = string.char(math.floor(value / 65536) % 256)
    if chunkPad < 2 then
      out[#out + 1] = string.char(math.floor(value / 256) % 256)
    end
    if chunkPad < 1 then
      out[#out + 1] = string.char(value % 256)
    end
    i = i + 4
  end
  return success(table.concat(out))
end

local function base64Encode(data: string): string
  return base64EncodeWith(data, BASE64, true)
end

local function base64Decode(text: string): DecodeResult
  return base64DecodeWith(text, BASE64, true)
end

local function base64UrlEncode(data: string): string
  return base64EncodeWith(data, BASE64URL, false)
end

local function base64UrlDecode(text: string): DecodeResult
  return base64DecodeWith(text, BASE64URL, false)
end

local function base32Encode(data: string): string
  local out: string[] = {}
  local buffer: integer = 0
  local bits: integer = 0
  for i: integer = 1, #data do
    buffer = math.floor(buffer * 256 + string.byte(data, i)!)
    bits = bits + 8
    while bits >= 5 do
      bits = bits - 5
      local index: integer = math.floor((buffer / 2 ^ bits) % 32)
      out[#out + 1] = string.sub(BASE32, index + 1, index + 1)
      buffer = math.floor(buffer % 2 ^ bits)
    end
  end
  if bits > 0 then
    local index: integer = math.floor((buffer * 2 ^ (5 - bits)) % 32)
    out[#out + 1] = string.sub(BASE32, index + 1, index + 1)
  end
  while #out % 8 ~= 0 do out[#out + 1] = "=" end
  return table.concat(out)
end

local function base32Value(byte: integer): integer
  if byte >= 65 and byte <= 90 then return byte - 65 end
  if byte >= 50 and byte <= 55 then return byte - 24 end
  return -1
end

local function base32Decode(text: string): DecodeResult
  local body: string = text
  local pad: integer = 0
  while #body > 0 and string.sub(body, -1) == "=" do
    pad = pad + 1
    body = string.sub(body, 1, -2)
  end
  if pad > 6 or string.find(body, "=") ~= nil then
    return failure("invalid Base32 padding")
  end
  local remainder: integer = #body % 8
  if remainder == 1 or remainder == 3 or remainder == 6 then
    return failure("invalid Base32 length")
  end
  local expectedPad: integer = 0
  if remainder == 2 then expectedPad = 6
  elseif remainder == 4 then expectedPad = 4
  elseif remainder == 5 then expectedPad = 3
  elseif remainder == 7 then expectedPad = 1
  end
  if pad ~= 0 and pad ~= expectedPad then
    return failure("invalid Base32 padding")
  end
  local out: string[] = {}
  local buffer: integer = 0
  local bits: integer = 0
  for i: integer = 1, #body do
    local value: integer = base32Value(string.byte(body, i)!)
    if value < 0 then return failure("invalid Base32 character") end
    buffer = math.floor(buffer * 32 + value)
    bits = bits + 5
    while bits >= 8 do
      bits = bits - 8
      out[#out + 1] = string.char(math.floor((buffer / 2 ^ bits) % 256))
      buffer = math.floor(buffer % 2 ^ bits)
    end
  end
  if bits > 0 and buffer ~= 0 then
    return failure("non-canonical Base32 trailing bits")
  end
  return success(table.concat(out))
end

local function hexEncode(data: string): string
  local out: string[] = {}
  for i: integer = 1, #data do
    local byte: integer = string.byte(data, i)!
    local high: integer = math.floor(byte / 16 + 1)
    local low: integer = math.floor(byte % 16 + 1)
    out[#out + 1] = string.sub(HEX_LOWER, high, high)
    out[#out + 1] = string.sub(HEX_LOWER, low, low)
  end
  return table.concat(out)
end

local function hexEncodeUpper(data: string): string
  local out: string[] = {}
  for i: integer = 1, #data do
    local byte: integer = string.byte(data, i)!
    local high: integer = math.floor(byte / 16 + 1)
    local low: integer = math.floor(byte % 16 + 1)
    out[#out + 1] = string.sub(HEX_UPPER, high, high)
    out[#out + 1] = string.sub(HEX_UPPER, low, low)
  end
  return table.concat(out)
end

local function hexValue(byte: integer): integer
  if byte >= 48 and byte <= 57 then return byte - 48 end
  if byte >= 65 and byte <= 70 then return byte - 55 end
  if byte >= 97 and byte <= 102 then return byte - 87 end
  return -1
end

local function hexDecode(text: string): DecodeResult
  if #text % 2 ~= 0 then return failure("hex string must have an even length") end
  local out: string[] = {}
  local i: integer = 1
  while i <= #text do
    local high: integer = hexValue(string.byte(text, i)!)
    local low: integer = hexValue(string.byte(text, i + 1)!)
    if high < 0 or low < 0 then return failure("invalid hex digit") end
    out[#out + 1] = string.char(high * 16 + low)
    i = i + 2
  end
  return success(table.concat(out))
end

local function isUnreserved(byte: integer): boolean
  return (byte >= 65 and byte <= 90)
    or (byte >= 97 and byte <= 122)
    or (byte >= 48 and byte <= 57)
    or byte == 45 or byte == 46 or byte == 95 or byte == 126
end

local function percentEncode(text: string): string
  local out: string[] = {}
  for i: integer = 1, #text do
    local byte: integer = string.byte(text, i)!
    if isUnreserved(byte) then
      out[#out + 1] = string.char(byte)
    else
      local high: integer = math.floor(byte / 16 + 1)
      local low: integer = math.floor(byte % 16 + 1)
      out[#out + 1] = "%" .. string.sub(HEX_UPPER, high, high)
        .. string.sub(HEX_UPPER, low, low)
    end
  end
  return table.concat(out)
end

local function percentDecode(text: string): DecodeResult
  local out: string[] = {}
  local i: integer = 1
  while i <= #text do
    local c: string = string.sub(text, i, i)
    if c == "%" then
      if i + 2 > #text then return failure("truncated percent escape") end
      local high: integer = hexValue(string.byte(text, i + 1)!)
      local low: integer = hexValue(string.byte(text, i + 2)!)
      if high < 0 or low < 0 then return failure("invalid percent escape") end
      out[#out + 1] = string.char(high * 16 + low)
      i = i + 3
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return success(table.concat(out))
end

local function formEncode(text: string): string
  local encoded: string = percentEncode(text)
  local out: string[] = {}
  local i: integer = 1
  while i <= #encoded do
    if string.sub(encoded, i, i + 2) == "%20" then
      out[#out + 1] = "+"
      i = i + 3
    else
      out[#out + 1] = string.sub(encoded, i, i)
      i = i + 1
    end
  end
  return table.concat(out)
end

local function formDecode(text: string): DecodeResult
  local replaced: string[] = {}
  for i: integer = 1, #text do
    local c: string = string.sub(text, i, i)
    local piece: string = c
    if c == "+" then piece = " " end
    replaced[#replaced + 1] = piece
  end
  return percentDecode(table.concat(replaced))
end

return {
  base64Encode = base64Encode,
  base64Decode = base64Decode,
  base64UrlEncode = base64UrlEncode,
  base64UrlDecode = base64UrlDecode,
  base32Encode = base32Encode,
  base32Decode = base32Decode,
  hexEncode = hexEncode,
  hexEncodeUpper = hexEncodeUpper,
  hexDecode = hexDecode,
  percentEncode = percentEncode,
  percentDecode = percentDecode,
  urlEncode = percentEncode,
  urlDecode = percentDecode,
  formEncode = formEncode,
  formDecode = formDecode,
}
