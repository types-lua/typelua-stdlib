import T from "tlua_test"
import std from "../init"
import fs from "../fs"

return {
  ["root facade exposes every module"] = function(): void
    T.eq(std.version, "v0.1.1", "version")
    T.eq(std.strings.trim(" x "), "x", "strings")
    T.eq(std.lists.sum({ 1, 2 }), 3, "lists")
    T.eq(std.maps.count<string, integer>({ a = 1 }), 1, "maps")
    T.eq(std.mathx.clamp(2, 0, 1), 1, "mathx")
    T.eq(std.path.join({ "a", "b" }), "a/b", "path")
    T.eq(std.encoding.hexEncode("\255"), "ff", "encoding")
    T.eq(std.json.decode("true").value, true, "json")
    T.eq(std.time.iso8601(0), "1970-01-01T00:00:00Z", "time")
    T.ok(std.fs ~= nil, "fs")
    T.ok(std.random.Random ~= nil, "random")
  end,

  ["JSON file round-trip"] = function(): void
    local file: string = os.tmpname()
    local value: any = {
      name = "typelua",
      tags = { "typed", "lua" },
      active = true,
      count = 3,
      missing = std.json.null,
    }
    local encoded: string = std.json.encodePretty(value, 2)
    T.ok(fs.writeFile(file, encoded).ok, "write")
    local read = fs.readFile(file)
    T.ok(read.ok, "read")
    local decoded = std.json.decode(read.data)
    T.ok(decoded.ok, "decode")
    T.eq(decoded.value["name"], "typelua", "name")
    T.eq(decoded.value["tags"][2], "lua", "tags")
    T.eq(decoded.value["active"], true, "active")
    T.eq(decoded.value["count"], 3, "count")
    T.eq(decoded.value["missing"], std.json.null, "null")
    fs.remove(file)
  end,

  ["path and encoding composition"] = function(): void
    local unsafe: string = "../a/../../b.txt"
    local normalized: string = std.path.normalize(unsafe)
    T.eq(normalized, "../../b.txt", "normalize")
    T.ok(not std.path.isWithin("/srv/root", std.path.join({ "/srv/root", normalized })), "escape rejected")
    local text: string = "hello world"
    local encoded: string = std.encoding.base64Encode(text)
    T.eq(std.encoding.base64Decode(encoded).data, text, "base64 round-trip")
  end,
}
