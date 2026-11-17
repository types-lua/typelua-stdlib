import T from "tlua_test"
import entropy from "../entropy"

return {
  ["secure bytes"] = function(): void
    if not entropy.available() then
      T.ok(true, "OS entropy unavailable; skipped")
      return
    end
    local result = entropy.bytes(32)
    T.ok(result.ok, "bytes ok")
    T.eq(#result.data, 32, "length")
    T.ok(not entropy.bytes(-1).ok, "negative")
    T.ok(not entropy.bytes(1024 * 1024 + 1).ok, "too many")
  end,

  ["UUID v4 shape"] = function(): void
    if not entropy.available() then
      T.ok(true, "OS entropy unavailable; skipped")
      return
    end
    local first = entropy.uuidV4()
    T.ok(first.ok, "uuid ok")
    T.eq(#first.value, 36, "uuid length")
    T.eq(string.sub(first.value, 9, 9), "-", "dash 1")
    T.eq(string.sub(first.value, 14, 14), "-", "dash 2")
    T.eq(string.sub(first.value, 19, 19), "-", "dash 3")
    T.eq(string.sub(first.value, 24, 24), "-", "dash 4")
    T.eq(string.sub(first.value, 15, 15), "4", "version nibble")
    local variant: string = string.lower(string.sub(first.value, 20, 20))
    T.ok(variant == "8" or variant == "9" or variant == "a" or variant == "b", "variant")
    local second = entropy.uuidV4()
    T.ok(second.ok, "second uuid")
    T.ok(first.value ~= second.value, "uuids differ")
  end,
}
