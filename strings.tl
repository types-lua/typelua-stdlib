--- Typed, byte-oriented string helpers.
---
--- This module deliberately mirrors the most common operations from Go's
--- `strings`, Python's `str`, JavaScript's `String` and Rust's `str` without
--- hiding Lua's 1-based indexing. `slice` is the one exception: it uses
--- 0-based, end-exclusive indexes, matching most modern standard libraries.
---
--- All functions operate on bytes. UTF-8 text is passed through unchanged; use
--- `chars` only on ASCII, or bring a UTF-8 library when code-point semantics
--- are required.

local WHITESPACE: string = " \t\r\n\v\f"

local function isSpaceByte(c: integer): boolean
  return c == 32 or c == 9 or c == 10 or c == 13 or c == 11 or c == 12
end

local function isAlpha(c: integer): boolean
  return (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
end

local function isDigit(c: integer): boolean
  return c >= 48 and c <= 57
end

local function isAlnum(c: integer): boolean
  return isAlpha(c) or isDigit(c)
end

local function isLower(c: integer): boolean
  return c >= 97 and c <= 122
end

local function findPlain(s: string, needle: string, start: integer): integer | nil
  local from: integer = start
  if from < 1 then from = 1 end
  if needle == "" then
    if from <= #s + 1 then return from end
    return nil
  end
  local last: integer = #s - #needle + 1
  while from <= last do
    if string.sub(s, from, from + #needle - 1) == needle then
      return from
    end
    from = from + 1
  end
  return nil
end

local function trimStart(s: string): string
  local i: integer = 1
  while i <= #s and isSpaceByte(string.byte(s, i)!) do
    i = i + 1
  end
  return string.sub(s, i)
end

local function trimEnd(s: string): string
  local i: integer = #s
  while i >= 1 and isSpaceByte(string.byte(s, i)!) do
    i = i - 1
  end
  return string.sub(s, 1, i)
end

local function trim(s: string): string
  return trimEnd(trimStart(s))
end

local function inSet(c: integer, chars: string): boolean
  return findPlain(chars, string.char(c), 1) ~= nil
end

local function trimStartChars(s: string, chars: string): string
  if chars == "" then return s end
  local i: integer = 1
  while i <= #s and inSet(string.byte(s, i)!, chars) do
    i = i + 1
  end
  return string.sub(s, i)
end

local function trimEndChars(s: string, chars: string): string
  if chars == "" then return s end
  local i: integer = #s
  while i >= 1 and inSet(string.byte(s, i)!, chars) do
    i = i - 1
  end
  return string.sub(s, 1, i)
end

local function trimChars(s: string, chars: string): string
  return trimEndChars(trimStartChars(s, chars), chars)
end

local function lower(s: string): string
  return string.lower(s)
end

local function upper(s: string): string
  return string.upper(s)
end

local function startsWith(s: string, prefix: string): boolean
  return #prefix <= #s and string.sub(s, 1, #prefix) == prefix
end

local function endsWith(s: string, suffix: string): boolean
  return #suffix <= #s and string.sub(s, #s - #suffix + 1) == suffix
end

local function contains(s: string, needle: string): boolean
  return findPlain(s, needle, 1) ~= nil
end

local function indexOf(s: string, needle: string): integer
  local at: integer | nil = findPlain(s, needle, 1)
  if at == nil then return 0 end
  return at!
end

local function indexOfFrom(s: string, needle: string, from: integer): integer
  if from < 1 then from = 1 end
  local at: integer | nil = findPlain(s, needle, from)
  if at == nil then return 0 end
  return at!
end

local function lastIndexOf(s: string, needle: string): integer
  local found: integer = 0
  local from: integer = 1
  while from <= #s + 1 do
    local at: integer | nil = findPlain(s, needle, from)
    if at == nil then break end
    found = at!
    from = at! + 1
  end
  return found
end

local function split(s: string, separator: string): string[]
  local out: string[] = {}
  if separator == "" then
    for i: integer = 1, #s do
      out[#out + 1] = string.sub(s, i, i)
    end
    return out
  end
  local start: integer = 1
  while true do
    local at: integer | nil = findPlain(s, separator, start)
    if at == nil then
      out[#out + 1] = string.sub(s, start)
      break
    end
    out[#out + 1] = string.sub(s, start, at! - 1)
    start = at! + #separator
  end
  return out
end

local function splitWhitespace(s: string): string[]
  local out: string[] = {}
  local i: integer = 1
  while i <= #s do
    local c: integer = string.byte(s, i)!
    if isSpaceByte(c) then
      i = i + 1
    else
      local start: integer = i
      while i <= #s and not isSpaceByte(string.byte(s, i)!) do
        i = i + 1
      end
      out[#out + 1] = string.sub(s, start, i - 1)
    end
  end
  return out
end

local function lines(s: string): string[]
  local out: string[] = {}
  if s == "" then return out end
  local start: integer = 1
  while true do
    local at: integer | nil = findPlain(s, "\n", start)
    local line: string
    if at == nil then
      line = string.sub(s, start)
      if line ~= "" then
        if string.sub(line, -1) == "\r" then line = string.sub(line, 1, -2) end
        out[#out + 1] = line
      end
      break
    end
    line = string.sub(s, start, at! - 1)
    if line ~= "" and string.sub(line, -1) == "\r" then
      line = string.sub(line, 1, -2)
    end
    out[#out + 1] = line
    start = at! + 1
  end
  return out
end

local function join(parts: string[], separator: string): string
  return table.concat(parts, separator)
end

local function replace(s: string, old: string, replacement: string): string
  if old == "" then return s end
  local out: string[] = {}
  local start: integer = 1
  while true do
    local at: integer | nil = findPlain(s, old, start)
    if at == nil then
      out[#out + 1] = string.sub(s, start)
      break
    end
    out[#out + 1] = string.sub(s, start, at! - 1)
    out[#out + 1] = replacement
    start = at! + #old
  end
  return table.concat(out)
end

local function replaceFirst(s: string, old: string, replacement: string): string
  if old == "" then return s end
  local at: integer | nil = findPlain(s, old, 1)
  if at == nil then return s end
  return string.sub(s, 1, at! - 1) .. replacement .. string.sub(s, at! + #old)
end

local function count(s: string, needle: string): integer
  if needle == "" then return 0 end
  local total: integer = 0
  local start: integer = 1
  while true do
    local at: integer | nil = findPlain(s, needle, start)
    if at == nil then break end
    total = total + 1
    start = at! + #needle
  end
  return total
end

local function repeatString(s: string, times: integer): string
  if times <= 0 then return "" end
  return string.rep(s, times)
end

local function padStart(s: string, width: integer, pad: string): string
  if width <= #s then return s end
  if pad == "" then return s end
  local need: integer = width - #s
  local repeats: integer = math.floor((need + #pad - 1) / #pad)
  local prefix: string = string.rep(pad, repeats)
  return string.sub(prefix, 1, need) .. s
end

local function padEnd(s: string, width: integer, pad: string): string
  if width <= #s then return s end
  if pad == "" then return s end
  local need: integer = width - #s
  local repeats: integer = math.floor((need + #pad - 1) / #pad)
  local suffix: string = string.rep(pad, repeats)
  return s .. string.sub(suffix, 1, need)
end

local function capitalize(s: string): string
  if s == "" then return s end
  local first: integer = string.byte(s, 1)!
  if isLower(first) then
    return string.char(first - 32) .. string.sub(s, 2)
  end
  return s
end

local function uncapitalize(s: string): string
  if s == "" then return s end
  local first: integer = string.byte(s, 1)!
  if first >= 65 and first <= 90 then
    return string.char(first + 32) .. string.sub(s, 2)
  end
  return s
end

local function truncate(s: string, maxLength: integer, suffix: string): string
  if maxLength < 0 then maxLength = 0 end
  if #s <= maxLength then return s end
  if maxLength <= #suffix then return string.sub(s, 1, maxLength) end
  return string.sub(s, 1, maxLength - #suffix) .. suffix
end

local function isBlank(s: string): boolean
  return trim(s) == ""
end

local function chars(s: string): string[]
  local out: string[] = {}
  for i: integer = 1, #s do
    out[#out + 1] = string.sub(s, i, i)
  end
  return out
end

local function slice(s: string, start: integer, finish: integer): string
  local length: integer = #s
  local from: integer = start
  local to: integer = finish
  if from < 0 then from = length + from end
  if to < 0 then to = length + to end
  if from < 0 then from = 0 end
  if to < 0 then to = 0 end
  if from > length then from = length end
  if to > length then to = length end
  if to <= from then return "" end
  return string.sub(s, from + 1, to)
end

local function words(s: string): string[]
  local out: string[] = {}
  local current: string[] = {}
  local previousWasLower: boolean = false
  local previousWasUpper: boolean = false
  local function flush(): void
    if #current > 0 then
      out[#out + 1] = table.concat(current)
      current = {}
    end
  end
  for i: integer = 1, #s do
    local c: integer = string.byte(s, i)!
    if isAlnum(c) then
      local upper: boolean = c >= 65 and c <= 90
      local nextIsLower: boolean = false
      if i < #s then nextIsLower = isLower(string.byte(s, i + 1)!) end
      if upper and #current > 0 and (previousWasLower or (previousWasUpper and nextIsLower)) then
        flush()
      end
      current[#current + 1] = string.char(c)
      previousWasLower = isLower(c) or isDigit(c)
      previousWasUpper = upper
    else
      flush()
      previousWasLower = false
      previousWasUpper = false
    end
  end
  flush()
  return out
end

local function lowerWords(s: string): string[]
  local list: string[] = words(s)
  for i: integer = 1, #list do
    list[i] = string.lower(list[i])
  end
  return list
end

local function snakeCase(s: string): string
  return table.concat(lowerWords(s), "_")
end

local function kebabCase(s: string): string
  return table.concat(lowerWords(s), "-")
end

local function camelCase(s: string): string
  local list: string[] = lowerWords(s)
  if #list == 0 then return "" end
  local out: string[] = { list[1] }
  for i: integer = 2, #list do
    out[#out + 1] = capitalize(list[i])
  end
  return table.concat(out)
end

local function pascalCase(s: string): string
  local list: string[] = lowerWords(s)
  local out: string[] = {}
  for i: integer = 1, #list do
    out[#out + 1] = capitalize(list[i])
  end
  return table.concat(out)
end

return {
  WHITESPACE = WHITESPACE,
  trim = trim,
  trimStart = trimStart,
  trimEnd = trimEnd,
  trimChars = trimChars,
  trimStartChars = trimStartChars,
  trimEndChars = trimEndChars,
  lower = lower,
  upper = upper,
  startsWith = startsWith,
  endsWith = endsWith,
  contains = contains,
  includes = contains,
  indexOf = indexOf,
  indexOfFrom = indexOfFrom,
  lastIndexOf = lastIndexOf,
  split = split,
  splitWhitespace = splitWhitespace,
  lines = lines,
  splitLines = lines,
  join = join,
  replace = replace,
  replaceFirst = replaceFirst,
  count = count,
  repeatString = repeatString,
  padStart = padStart,
  padEnd = padEnd,
  capitalize = capitalize,
  uncapitalize = uncapitalize,
  truncate = truncate,
  isBlank = isBlank,
  chars = chars,
  slice = slice,
  words = words,
  snakeCase = snakeCase,
  kebabCase = kebabCase,
  camelCase = camelCase,
  pascalCase = pascalCase,
}
