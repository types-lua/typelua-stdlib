--- POSIX path helpers.
---
--- The module is deliberately platform-neutral in syntax: `/` is the only
--- separator. It does not touch the filesystem and does not consult the
--- current working directory, so `isWithin` and `normalize` are useful for
--- static-file and archive security checks.
---
--- Empty paths normalize to `.`, matching common POSIX path libraries. Trailing
--- slashes are removed by `normalize`; `dirname("/")` and `basename("/")` keep
--- the root semantics documented below.

type PathParts = {
  root: string,
  dir: string,
  base: string,
  ext: string,
  name: string,
}

local function splitRaw(value: string): string[]
  local out: string[] = {}
  local start: integer = 1
  while true do
    local at: integer | nil = string.find(value, "/", start)
    if at == nil then
      out[#out + 1] = string.sub(value, start)
      break
    end
    out[#out + 1] = string.sub(value, start, at! - 1)
    start = at! + 1
  end
  return out
end

local function isAbsolute(path: string): boolean
  return string.sub(path, 1, 1) == "/"
end

local function normalize(path: string): string
  if path == "" then return "." end
  local absolute: boolean = isAbsolute(path)
  local raw: string[] = splitRaw(path)
  local out: string[] = {}
  for i: integer = 1, #raw do
    local part: string = raw[i]
    if part == "" or part == "." then
      -- skip
    elseif part == ".." then
      if #out > 0 and out[#out] ~= ".." then
        table.remove(out)
      elseif not absolute then
        out[#out + 1] = ".."
      end
    else
      out[#out + 1] = part
    end
  end
  local body: string = table.concat(out, "/")
  if absolute then
    if body == "" then return "/" end
    return "/" .. body
  end
  if body == "" then return "." end
  return body
end

local function join(parts: string[]): string
  local usable: string[] = {}
  for i: integer = 1, #parts do
    if parts[i] ~= "" then usable[#usable + 1] = parts[i] end
  end
  if #usable == 0 then return "." end
  return normalize(table.concat(usable, "/"))
end

local function lastSlash(value: string): integer
  local found: integer = 0
  local start: integer = 1
  while true do
    local at: integer | nil = string.find(value, "/", start)
    if at == nil then break end
    found = at!
    start = at! + 1
  end
  return found
end

local function dirname(path: string): string
  if path == "" then return "." end
  local stop: integer = #path
  while stop > 1 and string.sub(path, stop, stop) == "/" do
    stop = stop - 1
  end
  local trimmed: string = string.sub(path, 1, stop)
  if trimmed == "/" then return "/" end
  local at: integer = lastSlash(trimmed)
  if at == 0 then return "." end
  if at == 1 then return "/" end
  return normalize(string.sub(trimmed, 1, at - 1))
end

local function basename(path: string): string
  if path == "" then return "" end
  local stop: integer = #path
  while stop > 1 and string.sub(path, stop, stop) == "/" do
    stop = stop - 1
  end
  local trimmed: string = string.sub(path, 1, stop)
  if trimmed == "/" then return "" end
  local at: integer = lastSlash(trimmed)
  if at == 0 then return trimmed end
  return string.sub(trimmed, at + 1)
end

local function extname(path: string): string
  local base: string = basename(path)
  local at: integer = 0
  local start: integer = #base
  while start >= 1 do
    if string.sub(base, start, start) == "." then
      at = start
      break
    end
    start = start - 1
  end
  if at == 0 or at == 1 then return "" end
  return string.sub(base, at)
end

local function stem(path: string): string
  local base: string = basename(path)
  local extension: string = extname(path)
  if extension == "" then return base end
  return string.sub(base, 1, #base - #extension)
end

local function parse(path: string): PathParts
  local base: string = basename(path)
  local extension: string = extname(path)
  local root: string = ""
  if isAbsolute(path) then root = "/" end
  local parentValue: string = dirname(path)
  local parent: string = parentValue
  if parentValue == "." then
    parent = ""
  end
  local name: string = base
  if extension ~= "" then name = string.sub(base, 1, #base - #extension) end
  return {
    root = root,
    dir = parent,
    base = base,
    ext = extension,
    name = name,
  }
end

local function segments(path: string): string[]
  local normalized: string = normalize(path)
  if normalized == "." or normalized == "/" then return {} end
  local out: string[] = {}
  local raw: string[] = splitRaw(normalized)
  for i: integer = 1, #raw do
    if raw[i] ~= "" then out[#out + 1] = raw[i] end
  end
  return out
end

local function hasPrefix(container: string[], target: string[]): boolean
  if #target < #container then return false end
  for i: integer = 1, #container do
    if target[i] ~= container[i] then return false end
  end
  return true
end

local function leadingParents(parts: string[]): integer
  local count: integer = 0
  while count < #parts and parts[count + 1] == ".." do
    count = count + 1
  end
  return count
end

local function isWithin(base: string, target: string): boolean
  if isAbsolute(base) ~= isAbsolute(target) then return false end
  local baseParts: string[] = segments(base)
  local targetParts: string[] = segments(target)
  if leadingParents(targetParts) > leadingParents(baseParts) then
    return false
  end
  return hasPrefix(baseParts, targetParts)
end

local function relative(fromPath: string, toPath: string): string
  if isAbsolute(fromPath) ~= isAbsolute(toPath) then
    error("relative requires both paths to be absolute or both relative")
  end
  local fromParts: string[] = segments(fromPath)
  local toParts: string[] = segments(toPath)
  local common: integer = 0
  while common < #fromParts and common < #toParts
    and fromParts[common + 1] == toParts[common + 1] do
    common = common + 1
  end
  local out: string[] = {}
  for _: integer = common + 1, #fromParts do
    out[#out + 1] = ".."
  end
  for i: integer = common + 1, #toParts do
    out[#out + 1] = toParts[i]
  end
  if #out == 0 then return "." end
  return table.concat(out, "/")
end

local function withExtension(path: string, extension: string): string
  local base: string = basename(path)
  local current: string = extname(path)
  local suffix: string = extension
  if suffix ~= "" and string.sub(suffix, 1, 1) ~= "." then
    suffix = "." .. suffix
  end
  local without: string
  if current == "" then
    without = path
  else
    without = string.sub(path, 1, #path - #current)
  end
  return without .. suffix
end

local function removeExtension(path: string): string
  local current: string = extname(path)
  if current == "" then return path end
  return string.sub(path, 1, #path - #current)
end

local function toPosix(path: string): string
  local out: string[] = {}
  for i: integer = 1, #path do
    local c: string = string.sub(path, i, i)
    local piece: string = c
    if c == "\\" then piece = "/" end
    out[#out + 1] = piece
  end
  return table.concat(out)
end

return {
  SEPARATOR = "/",
  isAbsolute = isAbsolute,
  normalize = normalize,
  join = join,
  dirname = dirname,
  basename = basename,
  extname = extname,
  stem = stem,
  parse = parse,
  segments = segments,
  isWithin = isWithin,
  relative = relative,
  withExtension = withExtension,
  removeExtension = removeExtension,
  toPosix = toPosix,
}
