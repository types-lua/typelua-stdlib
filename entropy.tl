--- Operating-system entropy and UUID v4 helpers.
---
--- On POSIX systems this reads `/dev/urandom` directly; it never falls back to
--- the deterministic `random` module or the clock. If the device is
--- unavailable the result is an explicit error. UUIDs are generated from 122
--- random bits with the standard version/variant bits set.

import encoding from "./encoding"

type EntropyResult = {
  ok: boolean,
  data: string,
  error: string,
}

type UuidResult = {
  ok: boolean,
  value: string,
  error: string,
}

local DEFAULT_MAX_BYTES: integer = 1024 * 1024

local function readWithLimit(count: integer, maxBytes: integer): EntropyResult
  if count < 0 or count > maxBytes then
    return { ok = false, data = "", error = "entropy byte count is out of range" }
  end
  local handle: any = nil
  local openErr: any = nil
  handle, openErr = io.open("/dev/urandom", "rb")
  if handle == nil then
    return { ok = false, data = "", error = "os entropy unavailable: " .. tostring(openErr) }
  end
  local data: any = nil
  local readErr: any = nil
  data, readErr = handle:read(count)
  handle:close()
  if data == nil then
    return { ok = false, data = "", error = "os entropy read failed: " .. tostring(readErr) }
  end
  if #data ~= count then
    return { ok = false, data = "", error = "os entropy returned a short read" }
  end
  return { ok = true, data = data as string, error = "" }
end

local function bytes(count: integer): EntropyResult
  return readWithLimit(count, DEFAULT_MAX_BYTES)
end

local function available(): boolean
  local result: EntropyResult = bytes(1)
  return result.ok
end

local function uuidV4(): UuidResult
  local random: EntropyResult = bytes(16)
  if not random.ok then
    return { ok = false, value = "", error = random.error }
  end
  local raw: string = random.data
  local bytesOut: string[] = {}
  for i: integer = 1, 16 do bytesOut[i] = string.sub(raw, i, i) end
  local version: integer = string.byte(bytesOut[7], 1)!
  bytesOut[7] = string.char(4 * 16 + version % 16)
  local variant: integer = string.byte(bytesOut[9], 1)!
  bytesOut[9] = string.char(128 + variant % 64)
  local hex: string = encoding.hexEncode(table.concat(bytesOut))
  local value: string = string.sub(hex, 1, 8) .. "-"
    .. string.sub(hex, 9, 12) .. "-"
    .. string.sub(hex, 13, 16) .. "-"
    .. string.sub(hex, 17, 20) .. "-"
    .. string.sub(hex, 21, 32)
  return { ok = true, value = value, error = "" }
end

return {
  available = available,
  bytes = bytes,
  uuidV4 = uuidV4,
}
