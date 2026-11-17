--- CRC-32 (IEEE) and CRC-32C (Castagnoli) integrity checks.
---
--- Tables are generated at module load with portable 32-bit operations. Both
--- streaming forms are provided: `*Extend` chains finalized CRCs, which is the
--- shape LevelDB uses for WAL/table records. CRC is not a MAC; use
--- `hash.hmacSha256` when authenticity is required.

import bits from "./bitops"
local IEEE_POLY: integer = 3988292384
local CASTAGNOLI_POLY: integer = 2197175160

local function makeTable(polynomial: integer): integer[]
  local table32: integer[] = {}
  for i: integer = 0, 255 do
    local value: integer = i
    for _: integer = 1, 8 do
      if value % 2 == 1 then
        value = bits.bxor(math.floor(value / 2), polynomial)
      else
        value = math.floor(value / 2)
      end
    end
    table32[i + 1] = value
  end
  return table32
end

local IEEE_TABLE: integer[] = makeTable(IEEE_POLY)
local CASTAGNOLI_TABLE: integer[] = makeTable(CASTAGNOLI_POLY)

local function extendWith(crc: integer, data: string, table32: integer[]): integer
  local value: integer = bits.bnot(crc)
  for i: integer = 1, #data do
    local byte: integer = string.byte(data, i)!
    local index: integer = math.floor(bits.bxor(value, byte) % 256)
    value = bits.bxor(math.floor(value / 256), table32[index + 1])
  end
  return bits.bnot(value)
end

local function crc32Extend(crc: integer, data: string): integer
  return extendWith(crc, data, IEEE_TABLE)
end

local function crc32cExtend(crc: integer, data: string): integer
  return extendWith(crc, data, CASTAGNOLI_TABLE)
end

local function crc32(data: string): integer
  return crc32Extend(0, data)
end

local function crc32c(data: string): integer
  return crc32cExtend(0, data)
end

local function crc32Hex(data: string): string
  return string.format("%08x", crc32(data))
end

local function crc32cHex(data: string): string
  return string.format("%08x", crc32c(data))
end

--- LevelDB masks CRCs so a zero payload cannot produce a valid-looking zero.
local function crc32cMask(crc: integer): integer
  local rotated: integer = math.floor(bits.rshift(crc, 15) + bits.lshift(crc, 17))
  return math.floor((rotated + 2726488792) % 4294967296)
end

local function crc32cUnmask(masked: integer): integer
  local rotated: integer = math.floor((masked - 2726488792) % 4294967296)
  return math.floor((bits.rshift(rotated, 17) + bits.lshift(rotated, 15)) % 4294967296)
end

return {
  crc32 = crc32,
  crc32Extend = crc32Extend,
  crc32Hex = crc32Hex,
  crc32c = crc32c,
  crc32cExtend = crc32cExtend,
  crc32cHex = crc32cHex,
  crc32cMask = crc32cMask,
  crc32cUnmask = crc32cUnmask,
}
