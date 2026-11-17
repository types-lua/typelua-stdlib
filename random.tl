--- Deterministic pseudo-random numbers.
---
--- The generator is xorshift32 implemented with portable 32-bit arithmetic, so
--- sequences are identical on Lua 5.4 and LuaJIT/Lua 5.1. It is suitable for
--- simulations, games, sampling and test data, not for cryptography.
---
--- Module-level `choice`/`shuffle`/`sample` take an explicit `Random` so
--- applications never share hidden global state.

local MOD: integer = 4294967296

local XOR4: integer[][] = {}
for a: integer = 0, 15 do
  local row: integer[] = {}
  for b: integer = 0, 15 do
    local x: integer = a
    local y: integer = b
    local value: integer = 0
    local place: integer = 1
    for _: integer = 1, 4 do
      local abit: integer = x % 2
      local bbit: integer = y % 2
      if abit ~= bbit then value = value + place end
      x = math.floor(x / 2)
      y = math.floor(y / 2)
      place = place * 2
    end
    row[b] = value
  end
  XOR4[a] = row
end

local function bxor(a: integer, b: integer): integer
  local out: integer = 0
  local place: integer = 1
  local x: integer = a
  local y: integer = b
  for _: integer = 1, 8 do
    local xv: integer = x % 16
    local yv: integer = y % 16
    out = out + XOR4[xv][yv] * place
    x = math.floor(x / 16)
    y = math.floor(y / 16)
    place = place * 16
  end
  return out
end

local function lshift32(a: integer, bits: integer): integer
  if bits <= 0 then return a % MOD end
  if bits >= 32 then return 0 end
  local low: integer = a % 65536
  local high: integer = math.floor(a / 65536)
  local lowPart: number = (low * 2 ^ bits) % MOD
  local highPart: number = (high * 2 ^ bits) % 65536
  return math.floor((lowPart + highPart * 65536) % MOD)
end

local function rshift32(a: integer, bits: integer): integer
  if bits <= 0 then return a % MOD end
  if bits >= 32 then return 0 end
  return math.floor((a % MOD) / 2 ^ bits)
end

class Random {
  state: integer,

  constructor(seed: integer)
    local initial: integer = seed % MOD
    if initial == 0 then initial = 2463534242 end
    self.state = initial
  end,

  nextUint(): integer
    local x: integer = self.state
    x = bxor(x, lshift32(x, 13))
    x = bxor(x, rshift32(x, 17))
    x = bxor(x, lshift32(x, 5))
    self.state = x
    return x
  end,

  nextFloat(): number
    return self:nextUint() / MOD
  end,

  nextInt(minimum: integer, maximum: integer): integer
    if maximum < minimum then
      error("nextInt requires minimum <= maximum")
    end
    local range: integer = maximum - minimum + 1
    if range <= 0 or range > MOD then
      error("nextInt range must fit in 32 bits")
    end
    local limit: integer = math.floor((MOD / range) * range)
    while true do
      local value: integer = self:nextUint()
      if value < limit then
        return minimum + value % range
      end
    end
  end,

  bool(probability: number): boolean
    if probability < 0 or probability > 1 then
      error("bool probability must be 0..1")
    end
    return self:nextFloat() < probability
  end,

  nextBytes(count: integer): string
    if count < 0 then error("nextBytes count must be >= 0") end
    local out: string[] = {}
    for _: integer = 1, count do
      out[#out + 1] = string.char(self:nextUint() % 256)
    end
    return table.concat(out)
  end,
}

local function copy<T>(items: T[]): T[]
  local out: T[] = {}
  for i: integer = 1, #items do out[i] = items[i] end
  return out
end

local function choice<T>(rng: Random, items: T[]): T
  if #items == 0 then error("choice requires a non-empty array") end
  return items[rng:nextInt(1, #items)]
end

local function shuffle<T>(rng: Random, items: T[]): T[]
  local out: T[] = copy<T>(items)
  for i: integer = #out, 2, -1 do
    local j: integer = rng:nextInt(1, i)
    local temporary: T = out[i]
    out[i] = out[j]
    out[j] = temporary
  end
  return out
end

local function sample<T>(rng: Random, items: T[], count: integer): T[]
  if count < 0 or count > #items then
    error("sample count must be between 0 and the array length")
  end
  local out: T[] = copy<T>(items)
  for i: integer = 1, count do
    local j: integer = rng:nextInt(i, #out)
    local temporary: T = out[i]
    out[i] = out[j]
    out[j] = temporary
  end
  local result: T[] = {}
  for i: integer = 1, count do
    result[i] = out[i]
  end
  return result
end

return {
  Random = Random,
  choice = choice,
  shuffle = shuffle,
  sample = sample,
}
