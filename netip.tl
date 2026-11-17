--- Strict IP address and CIDR parsing/formatting.
---
--- IPv4 and IPv6 are parsed into byte strings and formatted canonically
--- (including RFC 5952 zero compression for IPv6). CIDR containment is
--- prefix-bit aware rather than string-prefix based, which makes this suitable
--- for allowlists, SSRF checks and network policy code.
---
--- No DNS resolution, zone identifiers or non-canonical IPv4 forms are
--- accepted.

type IpAddress = {
  version: integer,
  bytes: string,
}

type IpResult = {
  ok: boolean,
  ip: IpAddress | nil,
  error: string,
}

type Cidr = {
  ip: IpAddress,
  prefix: integer,
}

type CidrResult = {
  ok: boolean,
  cidr: Cidr | nil,
  error: string,
}

local function findChar(value: string, wanted: string, start: integer): integer
  local i: integer = start
  while i <= #value do
    if string.sub(value, i, i) == wanted then return i end
    i = i + 1
  end
  return 0
end

local function splitBy(value: string, separator: string): string[]
  local out: string[] = {}
  local start: integer = 1
  while start <= #value + 1 do
    local at: integer = findChar(value, separator, start)
    if at == 0 then
      out[#out + 1] = string.sub(value, start)
      break
    end
    out[#out + 1] = string.sub(value, start, at - 1)
    start = at + 1
  end
  return out
end

local function isDigits(value: string): boolean
  if value == "" then return false end
  for i: integer = 1, #value do
    local byte: integer = string.byte(value, i)!
    if byte < 48 or byte > 57 then return false end
  end
  return true
end

local function isHex(value: string): boolean
  if value == "" or #value > 4 then return false end
  for i: integer = 1, #value do
    local byte: integer = string.byte(value, i)!
    local digit: boolean = (byte >= 48 and byte <= 57)
      or (byte >= 65 and byte <= 70)
      or (byte >= 97 and byte <= 102)
    if not digit then return false end
  end
  return true
end

local MAX_TEXT: integer = 256

local function parseV4(text: string): IpResult
  if #text > MAX_TEXT then
    return { ok = false, ip = nil, error = "IP address text is too long" }
  end
  local parts: string[] = splitBy(text, ".")
  if #parts ~= 4 then
    return { ok = false, ip = nil, error = "IPv4 must have four octets" }
  end
  local bytes: string[] = {}
  for i: integer = 1, 4 do
    local part: string = parts[i]
    if not isDigits(part) then
      return { ok = false, ip = nil, error = "IPv4 octet must be numeric" }
    end
    if #part > 1 and string.sub(part, 1, 1) == "0" then
      return { ok = false, ip = nil, error = "IPv4 octet must not have leading zeroes" }
    end
    local value: number | nil = tonumber(part)
    if value == nil or value! > 255 then
      return { ok = false, ip = nil, error = "IPv4 octet is out of range" }
    end
    bytes[#bytes + 1] = string.char(math.floor(value!))
  end
  return {
    ok = true,
    ip = { version = 4, bytes = table.concat(bytes) },
    error = "",
  }
end

local function parseWords(part: string, allowV4AtEnd: boolean): (integer[], string)
  local words: integer[] = {}
  if part == "" then return words, "" end
  local pieces: string[] = splitBy(part, ":")
  for i: integer = 1, #pieces do
    local piece: string = pieces[i]
    if piece == "" then return words, "empty IPv6 group" end
    if findChar(piece, ".", 1) > 0 then
      if not allowV4AtEnd or i ~= #pieces then
        return words, "IPv4 is only valid at the end of IPv6"
      end
      local v4: IpResult = parseV4(piece)
      if not v4.ok then return words, v4.error end
      local raw: string = v4.ip!.bytes
      words[#words + 1] = math.floor(string.byte(raw, 1)! * 256 + string.byte(raw, 2)!)
      words[#words + 1] = math.floor(string.byte(raw, 3)! * 256 + string.byte(raw, 4)!)
    else
      if not isHex(piece) then return words, "invalid IPv6 group" end
      words[#words + 1] = tonumber(piece, 16)! as integer
    end
  end
  return words, ""
end

local function parseV6(text: string): IpResult
  if #text > MAX_TEXT then
    return { ok = false, ip = nil, error = "IP address text is too long" }
  end
  if text == "" or findChar(text, "%", 1) > 0 then
    return { ok = false, ip = nil, error = "invalid IPv6 address" }
  end
  local doubleAt: integer = 0
  local scan: integer = 1
  while scan < #text do
    if string.sub(text, scan, scan + 1) == "::" then
      if doubleAt ~= 0 then
        return { ok = false, ip = nil, error = "multiple '::' in IPv6" }
      end
      doubleAt = scan
      scan = scan + 2
    else
      scan = scan + 1
    end
  end

  local words: integer[] = {}
  if doubleAt > 0 then
    local left: string = string.sub(text, 1, doubleAt - 1)
    local right: string = string.sub(text, doubleAt + 2)
    local leftWords, leftErr = parseWords(left, false)
    if leftErr ~= "" then return { ok = false, ip = nil, error = leftErr } end
    local rightWords, rightErr = parseWords(right, true)
    if rightErr ~= "" then return { ok = false, ip = nil, error = rightErr } end
    local total: integer = #leftWords + #rightWords
    if total > 8 then
      return { ok = false, ip = nil, error = "too many IPv6 groups" }
    end
    for i: integer = 1, #leftWords do words[#words + 1] = leftWords[i] end
    for _: integer = 1, 8 - total do words[#words + 1] = 0 end
    for i: integer = 1, #rightWords do words[#words + 1] = rightWords[i] end
  else
    local parsed, err = parseWords(text, true)
    if err ~= "" then return { ok = false, ip = nil, error = err } end
    if #parsed ~= 8 then
      return { ok = false, ip = nil, error = "IPv6 must have eight groups" }
    end
    words = parsed
  end
  local bytes: string[] = {}
  for i: integer = 1, 8 do
    local word: integer = words[i]
    if word < 0 or word > 65535 then
      return { ok = false, ip = nil, error = "IPv6 group is out of range" }
    end
    bytes[#bytes + 1] = string.char(math.floor(word / 256), word % 256)
  end
  return {
    ok = true,
    ip = { version = 6, bytes = table.concat(bytes) },
    error = "",
  }
end

local function parse(text: string): IpResult
  if findChar(text, ":", 1) > 0 then return parseV6(text) end
  return parseV4(text)
end

local function formatV4(ip: IpAddress): string
  return tostring(string.byte(ip.bytes, 1)!)
    .. "." .. tostring(string.byte(ip.bytes, 2)!)
    .. "." .. tostring(string.byte(ip.bytes, 3)!)
    .. "." .. tostring(string.byte(ip.bytes, 4)!)
end

local function wordsOf(ip: IpAddress): integer[]
  local words: integer[] = {}
  for i: integer = 1, 8 do
    words[i] = math.floor(string.byte(ip.bytes, i * 2 - 1)! * 256
      + string.byte(ip.bytes, i * 2)!)
  end
  return words
end

local function formatV6(ip: IpAddress): string
  local words: integer[] = wordsOf(ip)
  local bestStart: integer = -1
  local bestLength: integer = 0
  local i: integer = 1
  while i <= 8 do
    if words[i] == 0 then
      local start: integer = i
      while i <= 8 and words[i] == 0 do i = i + 1 end
      local length: integer = i - start
      if length >= 2 and length > bestLength then
        bestStart = start
        bestLength = length
      end
    else
      i = i + 1
    end
  end
  local out: string[] = {}
  if bestStart < 0 then
    for index: integer = 1, 8 do
      out[#out + 1] = string.format("%x", words[index])
    end
    return table.concat(out, ":")
  end
  for index: integer = 1, bestStart - 1 do
    out[#out + 1] = string.format("%x", words[index])
  end
  local rightStart: integer = bestStart + bestLength
  local right: string[] = {}
  for index: integer = rightStart, 8 do
    right[#right + 1] = string.format("%x", words[index])
  end
  local leftText: string = table.concat(out, ":")
  local rightText: string = table.concat(right, ":")
  if leftText == "" and rightText == "" then return "::" end
  if leftText == "" then return "::" .. rightText end
  if rightText == "" then return leftText .. "::" end
  return leftText .. "::" .. rightText
end

local function format(ip: IpAddress): string
  if ip.version == 4 then return formatV4(ip) end
  return formatV6(ip)
end

local function isV4(ip: IpAddress): boolean
  return ip.version == 4
end

local function isV6(ip: IpAddress): boolean
  return ip.version == 6
end

local function equal(first: IpAddress, second: IpAddress): boolean
  return first.version == second.version and first.bytes == second.bytes
end

local function parseCidr(text: string): CidrResult
  if #text > MAX_TEXT + 4 then
    return { ok = false, cidr = nil, error = "CIDR text is too long" }
  end
  local slash: integer = findChar(text, "/", 1)
  if slash <= 1 or slash == #text then
    return { ok = false, cidr = nil, error = "CIDR must be address/prefix" }
  end
  local ipResult: IpResult = parse(string.sub(text, 1, slash - 1))
  if not ipResult.ok then
    return { ok = false, cidr = nil, error = ipResult.error }
  end
  local prefixText: string = string.sub(text, slash + 1)
  if not isDigits(prefixText) then
    return { ok = false, cidr = nil, error = "CIDR prefix must be numeric" }
  end
  local prefix: number | nil = tonumber(prefixText)
  local maximum: integer = 32
  if ipResult.ip!.version == 6 then maximum = 128 end
  if prefix == nil or prefix! < 0 or prefix! > maximum then
    return { ok = false, cidr = nil, error = "CIDR prefix is out of range" }
  end
  return {
    ok = true,
    cidr = { ip = ipResult.ip!, prefix = math.floor(prefix!) },
    error = "",
  }
end

local function formatCidr(cidr: Cidr): string
  return format(cidr.ip) .. "/" .. tostring(cidr.prefix)
end

local function maskedBytes(ip: IpAddress, prefix: integer): string
  local out: string[] = {}
  local full: integer = math.floor(prefix / 8)
  local remaining: integer = prefix % 8
  for i: integer = 1, #ip.bytes do
    local byte: integer = string.byte(ip.bytes, i)!
    if i <= full then
      out[#out + 1] = string.char(byte)
    elseif i == full + 1 and remaining > 0 then
      local mask: integer = math.floor(256 - 2 ^ (8 - remaining))
      out[#out + 1] = string.char(math.floor(byte / (256 - mask)) * (256 - mask))
    else
      out[#out + 1] = string.char(0)
    end
  end
  return table.concat(out)
end

local function network(cidr: Cidr): IpAddress
  return { version = cidr.ip.version, bytes = maskedBytes(cidr.ip, cidr.prefix) }
end

local function contains(cidr: Cidr, ip: IpAddress): boolean
  if cidr.ip.version ~= ip.version then return false end
  local full: integer = math.floor(cidr.prefix / 8)
  local remaining: integer = cidr.prefix % 8
  for i: integer = 1, full do
    if string.byte(cidr.ip.bytes, i) ~= string.byte(ip.bytes, i) then return false end
  end
  if remaining > 0 then
    local mask: integer = math.floor(256 - 2 ^ (8 - remaining))
    local a: integer = string.byte(cidr.ip.bytes, full + 1)!
    local b: integer = string.byte(ip.bytes, full + 1)!
    if math.floor(a / (256 - mask)) ~= math.floor(b / (256 - mask)) then
      return false
    end
  end
  return true
end

local function containsText(cidr: Cidr, ipText: string): boolean
  local parsed: IpResult = parse(ipText)
  if not parsed.ok then return false end
  return contains(cidr, parsed.ip!)
end

--- Returns the embedded IPv4 address for an IPv4-mapped IPv6 address
--- (`::ffff:a.b.c.d`), otherwise nil. Classification helpers use this so a
--- mapped loopback/private address cannot bypass policy checks.
local function mappedV4(ip: IpAddress): IpAddress | nil
  if ip.version ~= 6 then return nil end
  for i: integer = 1, 10 do
    if string.byte(ip.bytes, i) ~= 0 then return nil end
  end
  if string.byte(ip.bytes, 11) ~= 255 or string.byte(ip.bytes, 12) ~= 255 then
    return nil
  end
  return { version = 4, bytes = string.sub(ip.bytes, 13, 16) }
end

local function isV4Mapped(ip: IpAddress): boolean
  return mappedV4(ip) ~= nil
end

local function effective(ip: IpAddress): IpAddress
  local mapped: IpAddress | nil = mappedV4(ip)
  if mapped ~= nil then return mapped! end
  return ip
end

local function firstByte(ip: IpAddress): integer
  return string.byte(ip.bytes, 1)!
end

local function isUnspecified(ip: IpAddress): boolean
  local value: IpAddress = effective(ip)
  for i: integer = 1, #value.bytes do
    if string.byte(value.bytes, i) ~= 0 then return false end
  end
  return true
end

local function isLoopback(ip: IpAddress): boolean
  local value: IpAddress = effective(ip)
  if value.version == 4 then return firstByte(value) == 127 end
  return value.bytes == string.char(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)
end

local function isPrivate(ip: IpAddress): boolean
  local value: IpAddress = effective(ip)
  if value.version == 4 then
    local a: integer = string.byte(value.bytes, 1)!
    local b: integer = string.byte(value.bytes, 2)!
    if a == 10 then return true end
    if a == 172 and b >= 16 and b <= 31 then return true end
    if a == 192 and b == 168 then return true end
    return false
  end
  local first: integer = firstByte(value)
  return first >= 0xFC and first <= 0xFD
end

local function isLinkLocal(ip: IpAddress): boolean
  local value: IpAddress = effective(ip)
  if value.version == 4 then
    return string.byte(value.bytes, 1)! == 169 and string.byte(value.bytes, 2)! == 254
  end
  local first: integer = firstByte(value)
  local second: integer = string.byte(value.bytes, 2)!
  return first == 0xFE and second >= 0x80 and second <= 0xBF
end

local function isMulticast(ip: IpAddress): boolean
  local value: IpAddress = effective(ip)
  if value.version == 4 then
    local first: integer = firstByte(value)
    return first >= 224 and first <= 239
  end
  return firstByte(value) == 0xFF
end

return {
  parse = parse,
  parseV4 = parseV4,
  parseV6 = parseV6,
  format = format,
  formatCidr = formatCidr,
  isV4 = isV4,
  isV6 = isV6,
  equal = equal,
  parseCidr = parseCidr,
  network = network,
  contains = contains,
  containsText = containsText,
  isUnspecified = isUnspecified,
  isLoopback = isLoopback,
  isPrivate = isPrivate,
  isLinkLocal = isLinkLocal,
  isMulticast = isMulticast,
  isV4Mapped = isV4Mapped,
  mappedV4 = mappedV4,
}
