--- Semantic Versioning 2.0 parsing and precedence.
---
--- Parsing is strict: three numeric components, no leading zeroes in numeric
--- core/prerelease identifiers, non-empty dot-separated identifiers, and only
--- [0-9A-Za-z-] in prerelease/build identifiers. Build metadata is preserved
--- but ignored by precedence comparison, as required by SemVer.

type Semver = {
  major: integer,
  minor: integer,
  patch: integer,
  prerelease: string[],
  build: string[],
}

type SemverResult = {
  ok: boolean,
  version: Semver | nil,
  error: string,
}

local function findChar(text: string, wanted: string): integer
  for i: integer = 1, #text do
    if string.sub(text, i, i) == wanted then return i end
  end
  return 0
end

local function splitDots(text: string): string[]
  local out: string[] = {}
  if text == "" then return out end
  local start: integer = 1
  while start <= #text do
    local at: integer = 0
    for i: integer = start, #text do
      if string.sub(text, i, i) == "." then
        at = i
        break
      end
    end
    if at == 0 then
      out[#out + 1] = string.sub(text, start)
      break
    end
    out[#out + 1] = string.sub(text, start, at - 1)
    start = at + 1
  end
  return out
end

local function allDigits(text: string): boolean
  if text == "" then return false end
  for i: integer = 1, #text do
    local byte: integer = string.byte(text, i)!
    if byte < 48 or byte > 57 then return false end
  end
  return true
end

local function validIdentifier(text: string, numericNoLeadingZero: boolean): boolean
  if text == "" then return false end
  for i: integer = 1, #text do
    local byte: integer = string.byte(text, i)!
    local alpha: boolean = (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
    local digit: boolean = byte >= 48 and byte <= 57
    if not alpha and not digit and byte ~= 45 then return false end
  end
  if numericNoLeadingZero and allDigits(text) and #text > 1 and string.sub(text, 1, 1) == "0" then
    return false
  end
  return true
end

local function parse(text: string): SemverResult
  if #text == 0 or #text > 256 then
    return { ok = false, version = nil, error = "version must be 1..256 bytes" }
  end
  local build: string[] = {}
  local plus: integer = findChar(text, "+")
  local coreAndPre: string = text
  if plus > 0 then
    local buildText: string = string.sub(text, plus + 1)
    if buildText == "" then
      return { ok = false, version = nil, error = "empty build metadata" }
    end
    build = splitDots(buildText)
    for i: integer = 1, #build do
      if not validIdentifier(build[i], false) then
        return { ok = false, version = nil, error = "invalid build identifier" }
      end
    end
    coreAndPre = string.sub(text, 1, plus - 1)
  end
  local prerelease: string[] = {}
  local dash: integer = findChar(coreAndPre, "-")
  local core: string = coreAndPre
  if dash > 0 then
    local preText: string = string.sub(coreAndPre, dash + 1)
    if preText == "" then
      return { ok = false, version = nil, error = "empty prerelease" }
    end
    prerelease = splitDots(preText)
    for i: integer = 1, #prerelease do
      if not validIdentifier(prerelease[i], true) then
        return { ok = false, version = nil, error = "invalid prerelease identifier" }
      end
    end
    core = string.sub(coreAndPre, 1, dash - 1)
  end
  local parts: string[] = splitDots(core)
  if #parts ~= 3 then
    return { ok = false, version = nil, error = "version must have major.minor.patch" }
  end
  for i: integer = 1, 3 do
    if not allDigits(parts[i]) then
      return { ok = false, version = nil, error = "version components must be numeric" }
    end
    if #parts[i] > 1 and string.sub(parts[i], 1, 1) == "0" then
      return { ok = false, version = nil, error = "numeric components must not have leading zeroes" }
    end
  end
  local major: number | nil = tonumber(parts[1])
  local minor: number | nil = tonumber(parts[2])
  local patch: number | nil = tonumber(parts[3])
  if major == nil or minor == nil or patch == nil
    or major! ~= major! or minor! ~= minor! or patch! ~= patch!
    or major! == math.huge or minor! == math.huge or patch! == math.huge
    or major! < 0 or minor! < 0 or patch! < 0
    or major! > 9007199254740991 or minor! > 9007199254740991
    or patch! > 9007199254740991 then
    return { ok = false, version = nil, error = "numeric component is too large" }
  end
  return {
    ok = true,
    version = {
      major = math.floor(major!),
      minor = math.floor(minor!),
      patch = math.floor(patch!),
      prerelease = prerelease,
      build = build,
    },
    error = "",
  }
end

local function format(version: Semver): string
  local text: string = tostring(version.major) .. "." .. tostring(version.minor)
    .. "." .. tostring(version.patch)
  if #version.prerelease > 0 then
    text = text .. "-" .. table.concat(version.prerelease, ".")
  end
  if #version.build > 0 then
    text = text .. "+" .. table.concat(version.build, ".")
  end
  return text
end

local function comparePrerelease(first: string[], second: string[]): integer
  if #first == 0 and #second == 0 then return 0 end
  if #first == 0 then return 1 end
  if #second == 0 then return -1 end
  local length: integer = #first
  if #second < length then length = #second end
  for i: integer = 1, length do
    local a: string = first[i]
    local b: string = second[i]
    if a == b then
      -- continue
    else
      local an: boolean = allDigits(a)
      local bn: boolean = allDigits(b)
      if an and bn then
        if #a < #b then return -1 end
        if #a > #b then return 1 end
        if a < b then return -1 end
        if a > b then return 1 end
      elseif an then
        return -1
      elseif bn then
        return 1
      elseif a < b then
        return -1
      else
        return 1
      end
    end
  end
  if #first < #second then return -1 end
  if #first > #second then return 1 end
  return 0
end

local function compare(first: Semver, second: Semver): integer
  if first.major ~= second.major then
    if first.major < second.major then return -1 end
    return 1
  end
  if first.minor ~= second.minor then
    if first.minor < second.minor then return -1 end
    return 1
  end
  if first.patch ~= second.patch then
    if first.patch < second.patch then return -1 end
    return 1
  end
  return comparePrerelease(first.prerelease, second.prerelease)
end

local function isValid(text: string): boolean
  return parse(text).ok
end

local function compareText(first: string, second: string): integer
  local a = parse(first)
  local b = parse(second)
  if not a.ok then error("invalid version: " .. first) end
  if not b.ok then error("invalid version: " .. second) end
  return compare(a.version!, b.version!)
end

return {
  parse = parse,
  format = format,
  compare = compare,
  compareText = compareText,
  isValid = isValid,
}
