--- Portable SHA-1, SHA-256 and HMAC-SHA256.
---
--- These are pure Lua implementations intended for integrity checks, cache
--- keys, signatures verified elsewhere and protocol compatibility. They are
--- not a substitute for a vetted cryptographic library when side-channel
--- resistance or large-input performance is critical.
---
--- `constantTimeEqual` compares two byte strings without early exit on content;
--- length is still observable, which is normally acceptable for MAC tags.

import bits from "./bitops"
import encoding from "./encoding"

local SHA256_K: integer[] = {
  1116352408, 1899447441, 3049323471, 3921009573,
  961987163, 1508970993, 2453635748, 2870763221,
  3624381080, 310598401, 607225278, 1426881987,
  1925078388, 2162078206, 2614888103, 3248222580,
  3835390401, 4022224774, 264347078, 604807628,
  770255983, 1249150122, 1555081692, 1996064986,
  2554220882, 2821834349, 2952996808, 3210313671,
  3336571891, 3584528711, 113926993, 338241895,
  666307205, 773529912, 1294757372, 1396182291,
  1695183700, 1986661051, 2177026350, 2456956037,
  2730485921, 2820302411, 3259730800, 3345764771,
  3516065817, 3600352804, 4094571909, 275423344,
  430227734, 506948616, 659060556, 883997877,
  958139571, 1322822218, 1537002063, 1747873779,
  1955562222, 2024104815, 2227730452, 2361852424,
  2428436474, 2756734187, 3204031479, 3329325298,
}

local function wordBE(data: string, at: integer): integer
  local b1: integer = string.byte(data, at)!
  local b2: integer = string.byte(data, at + 1)!
  local b3: integer = string.byte(data, at + 2)!
  local b4: integer = string.byte(data, at + 3)!
  return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
end

local function appendBE32(out: string[], value: number): void
  local v: number = value % 4294967296
  out[#out + 1] = string.char(
    math.floor(v / 16777216) % 256,
    math.floor(v / 65536) % 256,
    math.floor(v / 256) % 256,
    v % 256
  )
end

local function padMessage(data: string): string
  local message: string = data .. "\128"
  local padding: integer = (56 - (#message % 64)) % 64
  message = message .. string.rep("\0", padding)
  local bitLength: number = #data * 8
  local high: number = math.floor(bitLength / 4294967296) % 4294967296
  local low: number = bitLength % 4294967296
  local lengths: string[] = {}
  appendBE32(lengths, high)
  appendBE32(lengths, low)
  return message .. table.concat(lengths)
end

local function sha256(data: string): string
  local h0: integer = 1779033703
  local h1: integer = 3144134277
  local h2: integer = 1013904242
  local h3: integer = 2773480762
  local h4: integer = 1359893119
  local h5: integer = 2600822924
  local h6: integer = 528734635
  local h7: integer = 1541459225
  local message: string = padMessage(data)
  local w: integer[] = {}
  local offset: integer = 1
  while offset <= #message do
    for i: integer = 1, 16 do
      w[i] = wordBE(message, offset + (i - 1) * 4)
    end
    for i: integer = 17, 64 do
      local s0: integer = bits.bxor(
        bits.bxor(bits.rotr(w[i - 15], 7), bits.rotr(w[i - 15], 18)),
        bits.rshift(w[i - 15], 3)
      )
      local s1: integer = bits.bxor(
        bits.bxor(bits.rotr(w[i - 2], 17), bits.rotr(w[i - 2], 19)),
        bits.rshift(w[i - 2], 10)
      )
      w[i] = bits.add(bits.add(s1, w[i - 7]), bits.add(s0, w[i - 16]))
    end

    local a: integer = h0
    local b: integer = h1
    local c: integer = h2
    local d: integer = h3
    local e: integer = h4
    local f: integer = h5
    local g: integer = h6
    local h: integer = h7
    for i: integer = 1, 64 do
      local s1: integer = bits.bxor(
        bits.bxor(bits.rotr(e, 6), bits.rotr(e, 11)),
        bits.rotr(e, 25)
      )
      local ch: integer = bits.bxor(
        bits.band(e, f),
        bits.band(bits.bnot(e), g)
      )
      local temp1: integer = bits.add(
        bits.add(bits.add(h, s1), bits.add(ch, SHA256_K[i])),
        w[i]
      )
      local s0: integer = bits.bxor(
        bits.bxor(bits.rotr(a, 2), bits.rotr(a, 13)),
        bits.rotr(a, 22)
      )
      local majority: integer = bits.bxor(
        bits.bxor(bits.band(a, b), bits.band(a, c)),
        bits.band(b, c)
      )
      local temp2: integer = bits.add(s0, majority)
      h = g
      g = f
      f = e
      e = bits.add(d, temp1)
      d = c
      c = b
      b = a
      a = bits.add(temp1, temp2)
    end
    h0 = bits.add(h0, a)
    h1 = bits.add(h1, b)
    h2 = bits.add(h2, c)
    h3 = bits.add(h3, d)
    h4 = bits.add(h4, e)
    h5 = bits.add(h5, f)
    h6 = bits.add(h6, g)
    h7 = bits.add(h7, h)
    offset = offset + 64
  end
  local out: string[] = {}
  appendBE32(out, h0)
  appendBE32(out, h1)
  appendBE32(out, h2)
  appendBE32(out, h3)
  appendBE32(out, h4)
  appendBE32(out, h5)
  appendBE32(out, h6)
  appendBE32(out, h7)
  return table.concat(out)
end

local function sha1(data: string): string
  local h0: integer = 1732584193
  local h1: integer = 4023233417
  local h2: integer = 2562383102
  local h3: integer = 271733878
  local h4: integer = 3285377520
  local message: string = padMessage(data)
  local w: integer[] = {}
  local offset: integer = 1
  while offset <= #message do
    for i: integer = 1, 16 do
      w[i] = wordBE(message, offset + (i - 1) * 4)
    end
    for i: integer = 17, 80 do
      w[i] = bits.rotl(
        bits.bxor(bits.bxor(w[i - 3], w[i - 8]), bits.bxor(w[i - 14], w[i - 16])),
        1
      )
    end
    local a: integer = h0
    local b: integer = h1
    local c: integer = h2
    local d: integer = h3
    local e: integer = h4
    for i: integer = 1, 80 do
      local f: integer = 0
      local k: integer = 0
      if i <= 20 then
        f = bits.bor(bits.band(b, c), bits.band(bits.bnot(b), d))
        k = 1518500249
      elseif i <= 40 then
        f = bits.bxor(bits.bxor(b, c), d)
        k = 1859775393
      elseif i <= 60 then
        f = bits.bor(bits.bor(bits.band(b, c), bits.band(b, d)), bits.band(c, d))
        k = 2400959708
      else
        f = bits.bxor(bits.bxor(b, c), d)
        k = 3395469782
      end
      local temp: integer = bits.add(
        bits.add(bits.add(bits.rotl(a, 5), f), bits.add(e, k)),
        w[i]
      )
      e = d
      d = c
      c = bits.rotl(b, 30)
      b = a
      a = temp
    end
    h0 = bits.add(h0, a)
    h1 = bits.add(h1, b)
    h2 = bits.add(h2, c)
    h3 = bits.add(h3, d)
    h4 = bits.add(h4, e)
    offset = offset + 64
  end
  local out: string[] = {}
  appendBE32(out, h0)
  appendBE32(out, h1)
  appendBE32(out, h2)
  appendBE32(out, h3)
  appendBE32(out, h4)
  return table.concat(out)
end

local function hmacSha256(key: string, data: string): string
  local blockKey: string = key
  if #blockKey > 64 then blockKey = sha256(blockKey) end
  if #blockKey < 64 then blockKey = blockKey .. string.rep("\0", 64 - #blockKey) end
  local inner: string[] = {}
  local outer: string[] = {}
  for i: integer = 1, 64 do
    local byte: integer = string.byte(blockKey, i)!
    inner[#inner + 1] = string.char(bits.bxor(byte, 54))
    outer[#outer + 1] = string.char(bits.bxor(byte, 92))
  end
  return sha256(table.concat(outer) .. sha256(table.concat(inner) .. data))
end

local function constantTimeEqual(first: string, second: string): boolean
  local difference: integer = 0
  if #first ~= #second then difference = 1 end
  local maximum: integer = #first
  if #second > maximum then maximum = #second end
  for i: integer = 1, maximum do
    local a: integer = 0
    local b: integer = 0
    if i <= #first then a = string.byte(first, i)! end
    if i <= #second then b = string.byte(second, i)! end
    difference = math.floor(difference + bits.bxor(a, b))
  end
  return difference == 0
end

return {
  sha1 = sha1,
  sha1Hex = function(data: string): string return encoding.hexEncode(sha1(data)) end,
  sha256 = sha256,
  sha256Hex = function(data: string): string return encoding.hexEncode(sha256(data)) end,
  hmacSha256 = hmacSha256,
  hmacSha256Hex = function(key: string, data: string): string
    return encoding.hexEncode(hmacSha256(key, data))
  end,
  constantTimeEqual = constantTimeEqual,
}
