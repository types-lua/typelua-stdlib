--- Typed dictionary/map helpers.
---
--- Maps are ordinary Lua tables with `map<K, V>` semantics. Iteration order is
--- unspecified, matching Lua; callers that need deterministic output must sort
--- `keys` themselves. All helpers except the explicit mutators (`set`,
--- `remove`, `clear`) return a new table and leave their inputs untouched.

type Entry<K, V> = {
  key: K,
  value: V,
}

local function isEmpty<K, V>(m: map<K, V>): boolean
  for _ in pairs(m) do return false end
  return true
end

local function count<K, V>(m: map<K, V>): integer
  local total: integer = 0
  for _ in pairs(m) do total = total + 1 end
  return total
end

local function keys<K, V>(m: map<K, V>): K[]
  local out: K[] = {}
  for key, _ in pairs(m) do
    out[#out + 1] = key
  end
  return out
end

local function values<K, V>(m: map<K, V>): V[]
  local out: V[] = {}
  for _, value in pairs(m) do
    out[#out + 1] = value
  end
  return out
end

local function entries<K, V>(m: map<K, V>): Entry<K, V>[]
  local out: Entry<K, V>[] = {}
  for key, value in pairs(m) do
    out[#out + 1] = { key = key, value = value }
  end
  return out
end

local function fromEntries<K, V>(items: Entry<K, V>[]): map<K, V>
  local out: map<K, V> = {}
  for i: integer = 1, #items do
    out[items[i].key] = items[i].value
  end
  return out
end

local function has<K, V>(m: map<K, V>, key: K): boolean
  return m[key] ~= nil
end

local function get<K, V>(m: map<K, V>, key: K, fallback: V): V
  local value: V | nil = m[key]
  if value == nil then return fallback end
  return value!
end

local function getOrNil<K, V>(m: map<K, V>, key: K): V | nil
  return m[key]
end

local function set<K, V>(m: map<K, V>, key: K, value: V): void
  m[key] = value
end

local function remove<K, V>(m: map<K, V>, key: K): V | nil
  local value: V | nil = m[key]
  if value == nil then return nil end
  local raw: any = m
  raw[key] = nil
  return value!
end

local function clone<K, V>(m: map<K, V>): map<K, V>
  local out: map<K, V> = {}
  for key, value in pairs(m) do
    out[key] = value
  end
  return out
end

local function merge<K, V>(first: map<K, V>, second: map<K, V>): map<K, V>
  local out: map<K, V> = clone<K, V>(first)
  for key, value in pairs(second) do
    out[key] = value
  end
  return out
end

local function mergeInto<K, V>(target: map<K, V>, source: map<K, V>): void
  for key, value in pairs(source) do
    target[key] = value
  end
end

local function pick<K, V>(m: map<K, V>, wanted: K[]): map<K, V>
  local out: map<K, V> = {}
  for i: integer = 1, #wanted do
    local value: V | nil = m[wanted[i]]
    if value ~= nil then out[wanted[i]] = value! end
  end
  return out
end

local function omit<K, V>(m: map<K, V>, unwanted: K[]): map<K, V>
  local out: map<K, V> = {}
  for key, value in pairs(m) do
    local skip: boolean = false
    for i: integer = 1, #unwanted do
      if key == unwanted[i] then
        skip = true
        break
      end
    end
    if not skip then out[key] = value end
  end
  return out
end

local function invert(m: map<string, string>): map<string, string>
  local out: map<string, string> = {}
  for key, value in pairs(m) do
    if out[value] ~= nil then
      error("invert encountered duplicate value: " .. value)
    end
    out[value] = key
  end
  return out
end

local function mapValues<K, V, U>(
  m: map<K, V>,
  fn: (value: V, key: K) -> U
): map<K, U>
  local out: map<K, U> = {}
  for key, value in pairs(m) do
    out[key] = fn(value, key)
  end
  return out
end

local function filter<K, V>(
  m: map<K, V>,
  predicate: (key: K, value: V) -> boolean
): map<K, V>
  local out: map<K, V> = {}
  for key, value in pairs(m) do
    if predicate(key, value) then out[key] = value end
  end
  return out
end

local function forEach<K, V>(
  m: map<K, V>,
  fn: (key: K, value: V) -> void
): void
  for key, value in pairs(m) do
    fn(key, value)
  end
end

local function equals<K, V>(first: map<K, V>, second: map<K, V>): boolean
  if count<K, V>(first) ~= count<K, V>(second) then return false end
  for key, value in pairs(first) do
    local other: V | nil = second[key]
    if other == nil or other! ~= value then return false end
  end
  return true
end

local function clear<K, V>(m: map<K, V>): void
  local all: K[] = keys<K, V>(m)
  local raw: any = m
  for i: integer = 1, #all do
    raw[all[i]] = nil
  end
end

local function toArray<K, V>(m: map<K, V>): Entry<K, V>[]
  return entries<K, V>(m)
end

return {
  isEmpty = isEmpty,
  count = count,
  keys = keys,
  values = values,
  entries = entries,
  toArray = toArray,
  fromEntries = fromEntries,
  has = has,
  get = get,
  getOrNil = getOrNil,
  set = set,
  remove = remove,
  clone = clone,
  merge = merge,
  mergeInto = mergeInto,
  pick = pick,
  omit = omit,
  invert = invert,
  mapValues = mapValues,
  filter = filter,
  forEach = forEach,
  equals = equals,
  clear = clear,
}
