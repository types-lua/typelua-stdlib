import T from "tlua_test"
import encoding from "../encoding"
import json from "../json"
import path from "../path"
import time from "../time"
import random from "../random"

local function randomString(rng: any, maxLength: integer): string
  local length: integer = rng:nextInt(0, maxLength)
  local out: string[] = {}
  for _: integer = 1, length do
    out[#out + 1] = string.char(rng:nextInt(32, 126))
  end
  return table.concat(out)
end

local function randomValue(rng: any, depth: integer): any
  local kind: integer = rng:nextInt(1, 6)
  if kind == 1 then return json.null end
  if kind == 2 then return rng:bool(0.5) end
  if kind == 3 then return rng:nextInt(-100000, 100000) end
  if kind == 4 then
    return randomString(rng, 12) .. "\"\\\n\t"
  end
  if depth <= 0 then return rng:nextInt(0, 100) end
  if kind == 5 then
    local array: any[] = {}
    local count: integer = rng:nextInt(1, 4)
    for _: integer = 1, count do
      array[#array + 1] = randomValue(rng, depth - 1)
    end
    return array
  end
  local object: map<string, any> = { key = randomValue(rng, depth - 1) }
  local count: integer = rng:nextInt(1, 3)
  for i: integer = 1, count do
    object["k" .. tostring(i)] = randomValue(rng, depth - 1)
  end
  return object
end

return {
  ["Base64 and hex round-trip random bytes"] = function(): void
    local rng = random.Random.new(1234)
    for length: integer = 0, 128 do
      local bytes: string = rng:nextBytes(length)
      local encoded: string = encoding.base64Encode(bytes)
      local decoded = encoding.base64Decode(encoded)
      T.ok(decoded.ok, "base64 ok at " .. tostring(length))
      T.eq(decoded.data, bytes, "base64 at " .. tostring(length))
      local urlEncoded: string = encoding.base64UrlEncode(bytes)
      local urlDecoded = encoding.base64UrlDecode(urlEncoded)
      T.ok(urlDecoded.ok, "base64url ok at " .. tostring(length))
      T.eq(urlDecoded.data, bytes, "base64url at " .. tostring(length))
      T.eq(encoding.hexDecode(encoding.hexEncode(bytes)).data, bytes, "hex at " .. tostring(length))
    end
  end,

  ["JSON randomized round-trip"] = function(): void
    local rng = random.Random.new(5678)
    for _: integer = 1, 200 do
      local value: any = randomValue(rng, 3)
      local encoded: string = json.encode(value)
      local decoded = json.decode(encoded)
      T.ok(decoded.ok, "decode random")
      T.eq(json.encode(decoded.value), encoded, "canonical round-trip")
    end
  end,

  ["path normalization is idempotent"] = function(): void
    local rng = random.Random.new(9012)
    local parts: string[] = { "a", "b", "..", ".", "" }
    for _: integer = 1, 300 do
      local pieces: string[] = {}
      local count: integer = rng:nextInt(1, 5)
      for _: integer = 1, count do
        pieces[#pieces + 1] = parts[rng:nextInt(1, #parts)]
      end
      local input: string = table.concat(pieces, "/")
      if rng:bool(0.3) then input = "/" .. input end
      local once: string = path.normalize(input)
      local twice: string = path.normalize(once)
      T.eq(twice, once, "idempotent: " .. input)
      T.eq(path.isAbsolute(once), path.isAbsolute(input), "absolute preserved: " .. input)
    end
  end,

  ["time civil round-trip over a wide range"] = function(): void
    local start: integer = -1000000
    local step: integer = 9973
    for timestamp: integer = start, 1000000, step do
      local parts = time.dateParts(timestamp)
      local rebuilt = time.fromParts({
        year = parts.year,
        month = parts.month,
        day = parts.day,
        hour = parts.hour,
        minute = parts.minute,
        second = parts.second,
      })
      T.ok(rebuilt.ok, "fromParts at " .. tostring(timestamp))
      T.eq(rebuilt.timestamp, timestamp, "round-trip at " .. tostring(timestamp))
      local parsed = time.parseIso8601(time.iso8601(timestamp))
      T.ok(parsed.ok, "ISO parse at " .. tostring(timestamp))
      T.eq(parsed.timestamp, timestamp, "ISO round-trip at " .. tostring(timestamp))
    end
  end,

  ["shuffle is a permutation"] = function(): void
    local rng = random.Random.new(3456)
    local items: integer[] = {}
    for i: integer = 1, 50 do items[i] = i end
    for _: integer = 1, 20 do
      local shuffled: integer[] = random.shuffle<integer>(rng, items)
      T.eq(#shuffled, #items, "shuffle length")
      local seen: map<integer, boolean> = {}
      for i: integer = 1, #shuffled do
        T.ok(not seen[shuffled[i]], "shuffle duplicate")
        seen[shuffled[i]] = true
      end
    end
  end,
}
