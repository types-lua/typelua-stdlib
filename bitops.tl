--- Portable 32-bit bit operations.
---
--- Lua 5.1/LuaJIT and Lua 5.4 disagree about bitwise syntax, so this module
--- uses nibble lookup tables. It is an internal building block for hashes and
--- other byte-oriented algorithms.

local MOD: integer = 4294967296

local AND4: integer[][] = {}
local OR4: integer[][] = {}
local XOR4: integer[][] = {}

local function smallOp(a: integer, b: integer, operation: string): integer
  local out: integer = 0
  local place: integer = 1
  local x: integer = a
  local y: integer = b
  for _: integer = 1, 4 do
    local abit: integer = x % 2
    local bbit: integer = y % 2
    local bitValue: integer = 0
    if operation == "and" then
      if abit == 1 and bbit == 1 then bitValue = 1 end
    elseif operation == "or" then
      if abit == 1 or bbit == 1 then bitValue = 1 end
    else
      if abit ~= bbit then bitValue = 1 end
    end
    out = out + bitValue * place
    x = math.floor(x / 2)
    y = math.floor(y / 2)
    place = place * 2
  end
  return out
end

for a: integer = 0, 15 do
  local andRow: integer[] = {}
  local orRow: integer[] = {}
  local xorRow: integer[] = {}
  for b: integer = 0, 15 do
    andRow[b] = smallOp(a, b, "and")
    orRow[b] = smallOp(a, b, "or")
    xorRow[b] = smallOp(a, b, "xor")
  end
  AND4[a] = andRow
  OR4[a] = orRow
  XOR4[a] = xorRow
end

local function op(a: integer, b: integer, table16: integer[][]): integer
  local out: integer = 0
  local place: integer = 1
  local x: integer = a % MOD
  local y: integer = b % MOD
  for _: integer = 1, 8 do
    local xv: integer = x % 16
    local yv: integer = y % 16
    out = out + table16[xv][yv] * place
    x = math.floor(x / 16)
    y = math.floor(y / 16)
    place = place * 16
  end
  return out
end

local function band(a: integer, b: integer): integer
  return op(a, b, AND4)
end

local function bor(a: integer, b: integer): integer
  return op(a, b, OR4)
end

local function bxor(a: integer, b: integer): integer
  return op(a, b, XOR4)
end

local function bnot(a: integer): integer
  return math.floor(4294967295 - (a % MOD))
end

local function lshift(a: integer, bits: integer): integer
  if bits <= 0 then return a % MOD end
  if bits >= 32 then return 0 end
  local low: integer = a % 65536
  local high: integer = math.floor(a / 65536)
  local lowPart: number = (low * 2 ^ bits) % MOD
  local highPart: number = (high * 2 ^ bits) % 65536
  return math.floor((lowPart + highPart * 65536) % MOD)
end

local function rshift(a: integer, bits: integer): integer
  if bits <= 0 then return a % MOD end
  if bits >= 32 then return 0 end
  return math.floor((a % MOD) / 2 ^ bits)
end

local function rotl(a: integer, bits: integer): integer
  local amount: integer = bits % 32
  if amount == 0 then return a % MOD end
  return (lshift(a, amount) + rshift(a, 32 - amount)) % MOD
end

local function rotr(a: integer, bits: integer): integer
  local amount: integer = bits % 32
  if amount == 0 then return a % MOD end
  return (rshift(a, amount) + lshift(a, 32 - amount)) % MOD
end

local function add(a: integer, b: integer): integer
  return math.floor((a + b) % MOD)
end

--- XOR a byte string with a repeating key (WebSocket masking, stream ciphers
--- in test code, etc.). An empty key returns the input unchanged.
local function xorRepeat(data: string, key: string): string
  if #key == 0 then return data end
  local out: string[] = {}
  local keyPosition: integer = 1
  for i: integer = 1, #data do
    local dataByte: integer = string.byte(data, i)!
    local keyByte: integer = string.byte(key, keyPosition)!
    local low: integer = XOR4[dataByte % 16][keyByte % 16]
    local high: integer = XOR4[math.floor(dataByte / 16)][math.floor(keyByte / 16)]
    out[#out + 1] = string.char(high * 16 + low)
    keyPosition = keyPosition + 1
    if keyPosition > #key then keyPosition = 1 end
  end
  return table.concat(out)
end

return {
  MOD = MOD,
  band = band,
  bor = bor,
  bxor = bxor,
  bnot = bnot,
  lshift = lshift,
  rshift = rshift,
  rotl = rotl,
  rotr = rotr,
  add = add,
  xorRepeat = xorRepeat,
}
