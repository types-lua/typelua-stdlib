--- Typed array/list helpers.
---
--- Arrays are ordinary Lua sequences (1-based). Functions that return a new
--- array never mutate their input; `sort` and `shuffle`-style helpers copy
--- first. Comparators are strict-less functions: `(a, b) -> boolean`.
---
--- TypeLua currently needs explicit generic arguments at call sites:
--- `lists.map<integer, string>(items, fn)`.

type Pair<A, B> = {
  first: A,
  second: B,
}

type Partition<T> = {
  pass: T[],
  fail: T[],
}

local function isEmpty<T>(items: T[]): boolean
  return #items == 0
end

local function map<T, U>(items: T[], fn: (item: T) -> U): U[]
  local out: U[] = {}
  for i: integer = 1, #items do
    out[i] = fn(items[i])
  end
  return out
end

local function filter<T>(items: T[], predicate: (item: T) -> boolean): T[]
  local out: T[] = {}
  for i: integer = 1, #items do
    if predicate(items[i]) then
      out[#out + 1] = items[i]
    end
  end
  return out
end

local function reduce<T, U>(
  items: T[],
  fn: (acc: U, item: T) -> U,
  initial: U
): U
  local acc: U = initial
  for i: integer = 1, #items do
    acc = fn(acc, items[i])
  end
  return acc
end

local function forEach<T>(items: T[], fn: (item: T) -> void): void
  for i: integer = 1, #items do
    fn(items[i])
  end
end

local function find<T>(items: T[], predicate: (item: T) -> boolean): T | nil
  for i: integer = 1, #items do
    if predicate(items[i]) then return items[i] end
  end
  return nil
end

local function findIndex<T>(items: T[], predicate: (item: T) -> boolean): integer
  for i: integer = 1, #items do
    if predicate(items[i]) then return i - 1 end
  end
  return -1
end

local function indexOf<T>(items: T[], value: T): integer
  for i: integer = 1, #items do
    if items[i] == value then return i - 1 end
  end
  return -1
end

local function lastIndexOf<T>(items: T[], value: T): integer
  for i: integer = #items, 1, -1 do
    if items[i] == value then return i - 1 end
  end
  return -1
end

local function contains<T>(items: T[], value: T): boolean
  return indexOf<T>(items, value) >= 0
end

local function some<T>(items: T[], predicate: (item: T) -> boolean): boolean
  for i: integer = 1, #items do
    if predicate(items[i]) then return true end
  end
  return false
end

local function every<T>(items: T[], predicate: (item: T) -> boolean): boolean
  for i: integer = 1, #items do
    if not predicate(items[i]) then return false end
  end
  return true
end

local function count<T>(items: T[], predicate: (item: T) -> boolean): integer
  local total: integer = 0
  for i: integer = 1, #items do
    if predicate(items[i]) then total = total + 1 end
  end
  return total
end

local function unique<T>(items: T[]): T[]
  local out: T[] = {}
  for i: integer = 1, #items do
    local value: T = items[i]
    local seen: boolean = false
    for j: integer = 1, #out do
      if out[j] == value then
        seen = true
        break
      end
    end
    if not seen then out[#out + 1] = value end
  end
  return out
end

local function copy<T>(items: T[]): T[]
  local out: T[] = {}
  for i: integer = 1, #items do out[i] = items[i] end
  return out
end

local function reverse<T>(items: T[]): T[]
  local out: T[] = {}
  for i: integer = #items, 1, -1 do
    out[#out + 1] = items[i]
  end
  return out
end

local function slice<T>(items: T[], start: integer, finish: integer): T[]
  local length: integer = #items
  local from: integer = start
  local to: integer = finish
  if from < 0 then from = length + from end
  if to < 0 then to = length + to end
  if from < 0 then from = 0 end
  if to < 0 then to = 0 end
  if from > length then from = length end
  if to > length then to = length end
  local out: T[] = {}
  local index: integer = 1
  for i: integer = from + 1, to do
    out[index] = items[i]
    index = index + 1
  end
  return out
end

local function take<T>(items: T[], n: integer): T[]
  if n <= 0 then return {} end
  return slice<T>(items, 0, n)
end

local function drop<T>(items: T[], n: integer): T[]
  if n <= 0 then return copy<T>(items) end
  return slice<T>(items, n, #items)
end

local function concat<T>(first: T[], second: T[]): T[]
  local out: T[] = {}
  for i: integer = 1, #first do out[#out + 1] = first[i] end
  for i: integer = 1, #second do out[#out + 1] = second[i] end
  return out
end

local function flatten<T>(items: T[][]): T[]
  local out: T[] = {}
  for i: integer = 1, #items do
    local inner: T[] = items[i]
    for j: integer = 1, #inner do
      out[#out + 1] = inner[j]
    end
  end
  return out
end

local function flatMap<T, U>(items: T[], fn: (item: T) -> U[]): U[]
  local out: U[] = {}
  for i: integer = 1, #items do
    local inner: U[] = fn(items[i])
    for j: integer = 1, #inner do
      out[#out + 1] = inner[j]
    end
  end
  return out
end

local function chunk<T>(items: T[], size: integer): T[][]
  if size <= 0 then error("chunk size must be positive") end
  local out: T[][] = {}
  local index: integer = 1
  while index <= #items do
    local last: integer = index + size - 1
    if last > #items then last = #items end
    local part: T[] = {}
    for i: integer = index, last do
      part[#part + 1] = items[i]
    end
    out[#out + 1] = part
    index = last + 1
  end
  return out
end

local function zip<A, B>(first: A[], second: B[]): Pair<A, B>[]
  local length: integer = #first
  if #second < length then length = #second end
  local out: Pair<A, B>[] = {}
  for i: integer = 1, length do
    out[i] = { first = first[i], second = second[i] }
  end
  return out
end

local function range(start: integer, finish: integer, step: integer): integer[]
  if step == 0 then error("range step must not be zero") end
  local out: integer[] = {}
  if step > 0 then
    local i: integer = start
    while i < finish do
      out[#out + 1] = i
      i = i + step
    end
  else
    local i: integer = start
    while i > finish do
      out[#out + 1] = i
      i = i + step
    end
  end
  return out
end

local function repeatValue<T>(value: T, count: integer): T[]
  local out: T[] = {}
  for _: integer = 1, count do
    out[#out + 1] = value
  end
  return out
end

local function sum(items: number[]): number
  local total: number = 0
  for i: integer = 1, #items do total = total + items[i] end
  return total
end

local function sumBy<T>(items: T[], fn: (item: T) -> number): number
  local total: number = 0
  for i: integer = 1, #items do total = total + fn(items[i]) end
  return total
end

local function minNumber(items: number[]): number
  if #items == 0 then error("minNumber requires at least one value") end
  local best: number = items[1]
  for i: integer = 2, #items do
    if items[i] < best then best = items[i] end
  end
  return best
end

local function maxNumber(items: number[]): number
  if #items == 0 then error("maxNumber requires at least one value") end
  local best: number = items[1]
  for i: integer = 2, #items do
    if items[i] > best then best = items[i] end
  end
  return best
end

local function mean(items: number[]): number
  if #items == 0 then error("mean requires at least one value") end
  return sum(items) / #items
end

local function sort<T>(items: T[], less: (a: T, b: T) -> boolean): T[]
  local out: T[] = copy<T>(items)
  table.sort(out, less)
  return out
end

local function sortNumbers(items: number[], descending: boolean): number[]
  local out: number[] = copy<number>(items)
  if descending then
    table.sort(out, function(a: number, b: number): boolean return a > b end)
  else
    table.sort(out, function(a: number, b: number): boolean return a < b end)
  end
  return out
end

local function sortStrings(items: string[], descending: boolean): string[]
  local out: string[] = copy<string>(items)
  if descending then
    table.sort(out, function(a: string, b: string): boolean return a > b end)
  else
    table.sort(out, function(a: string, b: string): boolean return a < b end)
  end
  return out
end

local function groupBy<T>(items: T[], keyFn: (item: T) -> string): map<string, T[]>
  local out: map<string, T[]> = {}
  for i: integer = 1, #items do
    local key: string = keyFn(items[i])
    local bucket: T[] = {}
    local existing: T[] | nil = out[key]
    if existing ~= nil then
      bucket = existing!
    else
      out[key] = bucket
    end
    bucket[#bucket + 1] = items[i]
  end
  return out
end

local function partition<T>(
  items: T[],
  predicate: (item: T) -> boolean
): Partition<T>
  local pass: T[] = {}
  local fail: T[] = {}
  for i: integer = 1, #items do
    if predicate(items[i]) then
      pass[#pass + 1] = items[i]
    else
      fail[#fail + 1] = items[i]
    end
  end
  return { pass = pass, fail = fail }
end

local function first<T>(items: T[]): T | nil
  if #items == 0 then return nil end
  return items[1]
end

local function last<T>(items: T[]): T | nil
  if #items == 0 then return nil end
  return items[#items]
end

return {
  isEmpty = isEmpty,
  map = map,
  filter = filter,
  reduce = reduce,
  forEach = forEach,
  find = find,
  findIndex = findIndex,
  indexOf = indexOf,
  lastIndexOf = lastIndexOf,
  contains = contains,
  includes = contains,
  some = some,
  every = every,
  count = count,
  unique = unique,
  copy = copy,
  reverse = reverse,
  slice = slice,
  take = take,
  drop = drop,
  concat = concat,
  flatten = flatten,
  flatMap = flatMap,
  chunk = chunk,
  zip = zip,
  range = range,
  repeatValue = repeatValue,
  sum = sum,
  sumBy = sumBy,
  minNumber = minNumber,
  maxNumber = maxNumber,
  mean = mean,
  sort = sort,
  sortNumbers = sortNumbers,
  sortStrings = sortStrings,
  groupBy = groupBy,
  partition = partition,
  first = first,
  last = last,
}
