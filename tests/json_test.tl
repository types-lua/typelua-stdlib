import T from "tlua_test"
import json from "../json"

return {
  ["decode primitives, arrays and objects"] = function(): void
    T.eq(json.decode("null").value, json.null, "null")
    T.eq(json.decode("true").value, true, "true")
    T.eq(json.decode("false").value, false, "false")
    T.eq(json.decode("0").value, 0, "zero")
    T.eq(json.decode("-12.5e2").value, -1250, "number")
    T.eq(json.decode("\"hello\"").value, "hello", "string")
    local array = json.decode("[1, true, null, \"x\"]")
    T.ok(array.ok, "array ok")
    T.eq(#array.value, 4, "array length")
    T.eq(array.value[2], true, "array bool")
    T.eq(array.value[3], json.null, "array null sentinel")
    local object = json.decode("{\"a\":1,\"b\":[2,3]}")
    T.ok(object.ok, "object ok")
    T.eq(object.value["a"], 1, "object a")
    T.eq(object.value["b"][2], 3, "object nested")
    T.eq(json.decode("{\"a\":1,\"a\":2}").value["a"], 2, "duplicate last wins")
    T.ok(not json.decode("").ok, "empty rejected")
    T.ok(not json.decode("1 2").ok, "trailing rejected")
    T.ok(not json.decode("{").ok, "unterminated object")
    T.ok(not json.decode("[1,]").ok, "trailing comma")
    T.ok(not json.decode("{\"a\":}").ok, "missing value")
  end,

  ["strings and Unicode escapes"] = function(): void
    T.eq(json.decode("\"a\\n\\t\\\"\\\\\"").value, "a\n\t\"\\", "escapes")
    T.eq(json.decode("\"\\u00e9\"").value, string.char(0xC3, 0xA9), "UTF-8 e-acute")
    T.eq(
      json.decode("\"\\ud83d\\ude00\"").value,
      string.char(0xF0, 0x9F, 0x98, 0x80),
      "surrogate pair"
    )
    T.ok(not json.decode("\"\\ud83d\"").ok, "lone high surrogate")
    T.ok(not json.decode("\"\\ude00\"").ok, "lone low surrogate")
    T.ok(not json.decode("\"\\uZZZZ\"").ok, "invalid unicode escape")
    T.ok(not json.decode("\"\\q\"").ok, "invalid escape")
    T.ok(not json.decode("\"a\nb\"").ok, "raw control char")
    T.ok(not json.decode("\"unterminated").ok, "unterminated string")
  end,

  ["numbers and limits"] = function(): void
    T.ok(not json.decode("01").ok, "leading zero")
    T.ok(not json.decode("+1").ok, "plus")
    T.ok(not json.decode(".5").ok, "missing integer")
    T.ok(not json.decode("1.").ok, "missing fraction")
    T.ok(not json.decode("1e").ok, "missing exponent")
    T.ok(not json.decode("NaN").ok, "NaN")
    T.ok(not json.decode("Infinity").ok, "Infinity")
    local limited = json.decodeWith("[[[]]]", { maxDepth = 2 })
    T.ok(not limited.ok, "max depth")
    local bytesLimited = json.decodeWith("true", { maxBytes = 3 })
    T.ok(not bytesLimited.ok, "max bytes")
    T.raises(function(): void json.decodeWith("true", { maxDepth = 0 }) end)
  end,

  ["encode values and deterministic objects"] = function(): void
    T.eq(json.encode(nil), "null", "nil null")
    T.eq(json.encode(json.null), "null", "sentinel null")
    T.eq(json.encode(true), "true", "bool")
    T.eq(json.encode(false), "false", "false")
    T.eq(json.encode(42), "42", "integer")
    T.eq(json.encode(-1.5), "-1.5", "float")
    T.eq(json.encode("a\n\"b\""), "\"a\\n\\\"b\\\"\"", "escape")
    T.eq(json.encode({ 1, 2, 3 }), "[1,2,3]", "array")
    T.eq(json.encode({ b = 2, a = 1 }), "{\"a\":1,\"b\":2}", "sorted object")
    T.eq(json.encode({}), "{}", "empty object")
    T.eq(json.encode({ 1, json.null, 3 }), "[1,null,3]", "null in array")
    T.eq(json.encodeResult(math.huge).ok, false, "non-finite")
    local cyclic: any = {}
    cyclic["self"] = cyclic
    T.ok(json.encodeResult(cyclic).ok == false, "cycle")
    T.ok(json.encodeResult({ a = 1, 2 }).ok == false, "mixed keys")
    T.ok(json.encodeResult({ [1] = "a", [3] = "b" }).ok == false, "sparse array")
    T.ok(json.encodeResult({ [true] = 1 }).ok == false, "non-string key")
    T.raises(function(): void json.encode(cyclic) end)
    local deep: any = 1
    for _: integer = 1, 600 do deep = { deep } end
    T.ok(json.encodeResult(deep).ok == false, "encode max depth")
  end,

  ["pretty printing and round-trip"] = function(): void
    local pretty: string = json.encodePretty({ b = { 1, 2 }, a = true }, 2)
    T.eq(
      pretty,
      "{\n  \"a\": true,\n  \"b\": [\n    1,\n    2\n  ]\n}",
      "pretty"
    )
    local decoded = json.decode(pretty)
    T.ok(decoded.ok, "pretty decodes")
    T.eq(decoded.value["a"], true, "pretty a")
    T.eq(decoded.value["b"][1], 1, "pretty b")
    local nested = { name = "typelua", values = { 1, 2, 3 }, ok = true, missing = json.null }
    local roundTrip = json.decode(json.encode(nested))
    T.ok(roundTrip.ok, "round-trip ok")
    T.eq(roundTrip.value["name"], "typelua", "round-trip string")
    T.eq(roundTrip.value["values"][3], 3, "round-trip array")
    T.eq(roundTrip.value["missing"], json.null, "round-trip null")
    T.eq(json.isNull(roundTrip.value["missing"]), true, "isNull")
  end,
}
