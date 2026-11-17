--- Strict absolute-URL parsing and deterministic query-string helpers.
---
--- The parser accepts hierarchical absolute URLs with optional authority,
--- userinfo, bracketed IPv6 hosts, ports, query and fragment. It rejects raw
--- control characters/spaces and malformed ports instead of guessing. It does
--- not perform DNS resolution, IDNA conversion or percent-decoding of path
--- components; pair it with `encoding` when decoded query values are needed.

import encoding from "./encoding"

type UrlParts = {
  scheme: string,
  username: string,
  password: string,
  host: string,
  port: integer,
  hasPort: boolean,
  path: string,
  query: string,
  fragment: string,
  hasAuthority: boolean,
  hasQuery: boolean,
  hasFragment: boolean,
}

type UrlResult = {
  ok: boolean,
  parts: UrlParts | nil,
  error: string,
}

type UrlOptions = {
  maxLength?: integer,
}

type QueryResult = {
  ok: boolean,
  values: map<string, string>,
  error: string,
}

local DEFAULT_MAX_LENGTH: integer = 8192

local function isControlOrSpace(byte: integer): boolean
  return byte < 32 or byte == 32 or byte == 127
end

local function findCharFrom(text: string, wanted: string, start: integer): integer
  local i: integer = start
  while i <= #text do
    if string.sub(text, i, i) == wanted then return i end
    i = i + 1
  end
  return 0
end

local function isSchemeStart(byte: integer): boolean
  return (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end

local function isSchemeChar(byte: integer): boolean
  return isSchemeStart(byte)
    or (byte >= 48 and byte <= 57)
    or byte == 43 or byte == 45 or byte == 46
end

local function parsePort(text: string): (integer, boolean)
  if text == "" then return 0, false end
  local value: integer = 0
  for i: integer = 1, #text do
    local byte: integer = string.byte(text, i)!
    if byte < 48 or byte > 57 then return 0, false end
    value = value * 10 + (byte - 48)
    if value > 65535 then return 0, false end
  end
  return value, true
end

local function parseWith(text: string, options: UrlOptions): UrlResult
  local maxLength: integer = DEFAULT_MAX_LENGTH
  local option: integer | nil = options.maxLength
  if option ~= nil then maxLength = option! end
  if maxLength < 1 then error("URL maxLength must be >= 1") end
  if #text == 0 or #text > maxLength then
    return { ok = false, parts = nil, error = "URL length is out of range" }
  end
  for i: integer = 1, #text do
    if isControlOrSpace(string.byte(text, i)!) then
      return { ok = false, parts = nil, error = "URL contains raw control/space characters" }
    end
  end
  local colon: integer = findCharFrom(text, ":", 1)
  if colon <= 1 then
    return { ok = false, parts = nil, error = "URL must start with a scheme" }
  end
  local scheme: string = string.sub(text, 1, colon - 1)
  if not isSchemeStart(string.byte(scheme, 1)!) then
    return { ok = false, parts = nil, error = "invalid scheme start" }
  end
  for i: integer = 2, #scheme do
    if not isSchemeChar(string.byte(scheme, i)!) then
      return { ok = false, parts = nil, error = "invalid scheme character" }
    end
  end
  scheme = string.lower(scheme)
  local rest: string = string.sub(text, colon + 1)
  local username: string = ""
  local password: string = ""
  local host: string = ""
  local port: integer = 0
  local hasPort: boolean = false
  local hasAuthority: boolean = false
  local path: string = rest
  local query: string = ""
  local fragment: string = ""
  local hasQuery: boolean = false
  local hasFragment: boolean = false

  if string.sub(rest, 1, 2) == "//" then
    hasAuthority = true
    local authorityStart: integer = 3
    local authorityEnd: integer = 0
    local scan: integer = authorityStart
    while scan <= #rest do
      local c: string = string.sub(rest, scan, scan)
      if c == "/" or c == "?" or c == "#" then
        authorityEnd = scan
        break
      end
      scan = scan + 1
    end
    if authorityEnd == 0 then authorityEnd = #rest + 1 end
    local authority: string = string.sub(rest, authorityStart, authorityEnd - 1)
    if authority == "" then
      return { ok = false, parts = nil, error = "empty URL authority" }
    end
    local at: integer = 0
    local search: integer = 1
    while true do
      local found: integer = findCharFrom(authority, "@", search)
      if found == 0 then break end
      at = found
      search = found + 1
    end
    local hostPort: string = authority
    if at > 0 then
      local userinfo: string = string.sub(authority, 1, at - 1)
      hostPort = string.sub(authority, at + 1)
      local passwordAt: integer = findCharFrom(userinfo, ":", 1)
      if passwordAt > 0 then
        username = string.sub(userinfo, 1, passwordAt - 1)
        password = string.sub(userinfo, passwordAt + 1)
      else
        username = userinfo
      end
    end
    if hostPort == "" then
      return { ok = false, parts = nil, error = "empty URL host" }
    end
    if string.sub(hostPort, 1, 1) == "[" then
      local closing: integer = findCharFrom(hostPort, "]", 2)
      if closing == 0 then
        return { ok = false, parts = nil, error = "unterminated IPv6 host" }
      end
      host = string.sub(hostPort, 2, closing - 1)
      if host == "" then
        return { ok = false, parts = nil, error = "empty IPv6 host" }
      end
      local tail: string = string.sub(hostPort, closing + 1)
      if tail ~= "" then
        if string.sub(tail, 1, 1) ~= ":" then
          return { ok = false, parts = nil, error = "invalid text after IPv6 host" }
        end
        port, hasPort = parsePort(string.sub(tail, 2))
        if not hasPort then
          return { ok = false, parts = nil, error = "invalid URL port" }
        end
      end
    else
      local portAt: integer = 0
      local search: integer = 1
      while true do
        local found: integer = findCharFrom(hostPort, ":", search)
        if found == 0 then break end
        portAt = found
        search = found + 1
      end
      if portAt > 0 then
        host = string.sub(hostPort, 1, portAt - 1)
        port, hasPort = parsePort(string.sub(hostPort, portAt + 1))
        if not hasPort then
          return { ok = false, parts = nil, error = "invalid URL port" }
        end
        if findCharFrom(host, ":", 1) > 0 then
          return { ok = false, parts = nil, error = "IPv6 host must be bracketed" }
        end
      else
        host = hostPort
      end
    end
    if host == "" then
      return { ok = false, parts = nil, error = "empty URL host" }
    end
    path = string.sub(rest, authorityEnd)
  end

  local queryAt: integer = findCharFrom(path, "?", 1)
  local fragmentAt: integer = findCharFrom(path, "#", 1)
  if queryAt > 0 and (fragmentAt == 0 or queryAt < fragmentAt) then
    hasQuery = true
    if fragmentAt > 0 then
      query = string.sub(path, queryAt + 1, fragmentAt - 1)
      hasFragment = true
      fragment = string.sub(path, fragmentAt + 1)
    else
      query = string.sub(path, queryAt + 1)
    end
    path = string.sub(path, 1, queryAt - 1)
  elseif fragmentAt > 0 then
    hasFragment = true
    fragment = string.sub(path, fragmentAt + 1)
    path = string.sub(path, 1, fragmentAt - 1)
  end
  if not hasAuthority and path == "" then
    return { ok = false, parts = nil, error = "URL has no path or authority" }
  end
  return {
    ok = true,
    parts = {
      scheme = scheme,
      username = username,
      password = password,
      host = host,
      port = port,
      hasPort = hasPort,
      path = path,
      query = query,
      fragment = fragment,
      hasAuthority = hasAuthority,
      hasQuery = hasQuery,
      hasFragment = hasFragment,
    },
    error = "",
  }
end

local function parse(text: string): UrlResult
  return parseWith(text, { maxLength = DEFAULT_MAX_LENGTH })
end

local function format(parts: UrlParts): string
  local out: string[] = { parts.scheme, ":" }
  if parts.hasAuthority then
    out[#out + 1] = "//"
    if parts.username ~= "" then
      out[#out + 1] = parts.username
      if parts.password ~= "" then
        out[#out + 1] = ":"
        out[#out + 1] = parts.password
      end
      out[#out + 1] = "@"
    end
    if findCharFrom(parts.host, ":", 1) > 0 then
      out[#out + 1] = "["
      out[#out + 1] = parts.host
      out[#out + 1] = "]"
    else
      out[#out + 1] = parts.host
    end
    if parts.hasPort then
      out[#out + 1] = ":"
      out[#out + 1] = tostring(parts.port)
    end
  end
  out[#out + 1] = parts.path
  if parts.hasQuery then
    out[#out + 1] = "?"
    out[#out + 1] = parts.query
  end
  if parts.hasFragment then
    out[#out + 1] = "#"
    out[#out + 1] = parts.fragment
  end
  return table.concat(out)
end

local function parseQuery(text: string): QueryResult
  local values: map<string, string> = {}
  if text == "" then return { ok = true, values = values, error = "" } end
  local start: integer = 1
  while start <= #text + 1 do
    local ampAt: integer = findCharFrom(text, "&", start)
    local part: string
    if ampAt == 0 then
      part = string.sub(text, start)
      start = #text + 2
    else
      part = string.sub(text, start, ampAt - 1)
      start = ampAt + 1
    end
    if part ~= "" then
      local eqAt: integer = findCharFrom(part, "=", 1)
      local keyText: string
      local valueText: string
      if eqAt == 0 then
        keyText = part
        valueText = ""
      else
        keyText = string.sub(part, 1, eqAt - 1)
        valueText = string.sub(part, eqAt + 1)
      end
      local key = encoding.formDecode(keyText)
      local value = encoding.formDecode(valueText)
      if not key.ok then return { ok = false, values = values, error = key.error } end
      if not value.ok then return { ok = false, values = values, error = value.error } end
      values[key.data] = value.data
    end
    if ampAt == 0 then break end
  end
  return { ok = true, values = values, error = "" }
end

local function buildQuery(values: map<string, string>): string
  local keys: string[] = {}
  for key, _ in pairs(values) do keys[#keys + 1] = key end
  table.sort(keys, function(a: string, b: string): boolean return a < b end)
  local out: string[] = {}
  for i: integer = 1, #keys do
    out[#out + 1] = encoding.formEncode(keys[i])
      .. "=" .. encoding.formEncode(values[keys[i]])
  end
  return table.concat(out, "&")
end

return {
  parse = parse,
  parseWith = parseWith,
  format = format,
  parseQuery = parseQuery,
  buildQuery = buildQuery,
}
