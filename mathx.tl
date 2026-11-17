--- Numeric helpers that are not in Lua's base `math` library.
---
--- Functions are pure and never mutate inputs. Integer helpers validate their
--- domains and raise a Lua error for invalid arguments; floating-point helpers
--- reject non-finite inputs where the result would otherwise be meaningless.

type DivMod = {
  quotient: integer,
  remainder: integer,
}

local function clamp(value: number, low: number, high: number): number
  if low > high then error("clamp: low must be <= high") end
  if value < low then return low end
  if value > high then return high end
  return value
end

local function clamp01(value: number): number
  return clamp(value, 0, 1)
end

local function sign(value: number): integer
  if value > 0 then return 1 end
  if value < 0 then return -1 end
  return 0
end

local function isFinite(value: number): boolean
  return value == value and value ~= math.huge and value ~= -math.huge
end

local function isIntegerNumber(value: number): boolean
  return isFinite(value) and math.floor(value) == value
end

local function gcd(a: integer, b: integer): integer
  local x: integer = math.abs(a)
  local y: integer = math.abs(b)
  while y ~= 0 do
    local nextValue: integer = math.floor(x % y)
    x = y
    y = nextValue
  end
  return x
end

local function lcm(a: integer, b: integer): integer
  if a == 0 or b == 0 then return 0 end
  local divisor: integer = gcd(a, b)
  return math.floor(math.abs(a / divisor) * math.abs(b))
end

local function isPrime(value: integer): boolean
  if value < 2 then return false end
  if value == 2 then return true end
  if value % 2 == 0 then return false end
  local divisor: integer = 3
  while divisor <= math.floor(value / divisor) do
    if value % divisor == 0 then return false end
    divisor = divisor + 2
  end
  return true
end

local function factorial(value: integer): number
  if value < 0 or value > 170 then
    error("factorial requires 0 <= n <= 170")
  end
  local result: number = 1
  for i: integer = 2, value do
    result = result * i
  end
  return result
end

local function fibonacci(index: integer): number
  if index < 0 then error("fibonacci requires n >= 0") end
  if index > 1476 then error("fibonacci result exceeds a Lua double") end
  if index == 0 then return 0 end
  if index == 1 then return 1 end
  local previous: number = 0
  local current: number = 1
  for _: integer = 2, index do
    local nextValue: number = previous + current
    previous = current
    current = nextValue
  end
  return current
end

local function round(value: number, digits: integer): number
  if not isFinite(value) then error("round requires a finite value") end
  if digits < 0 or digits > 15 then error("round digits must be 0..15") end
  local scale: number = 10 ^ digits
  local scaled: number = value * scale
  local rounded: number
  if scaled >= 0 then
    rounded = math.floor(scaled + 0.5)
  else
    rounded = math.ceil(scaled - 0.5)
  end
  return rounded / scale
end

local function approxEqual(a: number, b: number, epsilon: number): boolean
  if epsilon < 0 then error("approxEqual epsilon must be >= 0") end
  return math.abs(a - b) <= epsilon
end

local function lerp(a: number, b: number, t: number): number
  return a + (b - a) * t
end

local function inverseLerp(a: number, b: number, value: number): number
  if a == b then error("inverseLerp requires distinct endpoints") end
  return (value - a) / (b - a)
end

local function logBase(value: number, base: number): number
  if value <= 0 then error("logBase value must be positive") end
  if base <= 0 or base == 1 then error("logBase base must be positive and not 1") end
  return math.log(value) / math.log(base)
end

local function hypot(x: number, y: number): number
  local ax: number = math.abs(x)
  local ay: number = math.abs(y)
  if ax < ay then
    local temporary: number = ax
    ax = ay
    ay = temporary
  end
  if ax == 0 then return 0 end
  local ratio: number = ay / ax
  return ax * math.sqrt(1 + ratio * ratio)
end

local function divMod(a: integer, b: integer): DivMod
  if b == 0 then error("divMod by zero") end
  local quotient: integer = math.floor(a / b)
  return { quotient = quotient, remainder = a - quotient * b }
end

local function safeDivide(a: number, b: number, fallback: number): number
  if b == 0 then return fallback end
  return a / b
end

local function percent(part: number, total: number): number
  if total == 0 then error("percent total must not be zero") end
  return part / total * 100
end

local function sumValues(values: number[]): number
  local total: number = 0
  for i: integer = 1, #values do total = total + values[i] end
  return total
end

local function mean(values: number[]): number
  if #values == 0 then error("mean requires at least one value") end
  return sumValues(values) / #values
end

local function median(values: number[]): number
  if #values == 0 then error("median requires at least one value") end
  local sorted: number[] = {}
  for i: integer = 1, #values do sorted[i] = values[i] end
  table.sort(sorted, function(a: number, b: number): boolean return a < b end)
  local middle: integer = math.floor(#sorted / 2)
  if #sorted % 2 == 1 then
    return sorted[middle + 1]
  end
  return (sorted[middle] + sorted[middle + 1]) / 2
end

local function radians(degreesValue: number): number
  return math.rad(degreesValue)
end

local function degrees(radiansValue: number): number
  return math.deg(radiansValue)
end

return {
  clamp = clamp,
  clamp01 = clamp01,
  sign = sign,
  isFinite = isFinite,
  isInteger = isIntegerNumber,
  gcd = gcd,
  lcm = lcm,
  isPrime = isPrime,
  factorial = factorial,
  fibonacci = fibonacci,
  round = round,
  approxEqual = approxEqual,
  lerp = lerp,
  inverseLerp = inverseLerp,
  logBase = logBase,
  hypot = hypot,
  divMod = divMod,
  safeDivide = safeDivide,
  percent = percent,
  sum = sumValues,
  mean = mean,
  median = median,
  radians = radians,
  degrees = degrees,
}
