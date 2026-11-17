import T from "tlua_test"
import crc from "../crc32"

return {
  ["standard check vectors"] = function(): void
    T.eq(crc.crc32Hex(""), "00000000", "empty CRC32")
    T.eq(crc.crc32Hex("123456789"), "cbf43926", "CRC32 vector")
    T.eq(crc.crc32cHex(""), "00000000", "empty CRC32C")
    T.eq(crc.crc32cHex("123456789"), "e3069283", "CRC32C vector")
    T.eq(crc.crc32cHex(string.rep("a", 1000)), "9f19ef6a", "CRC32C multi-block")
    T.eq(crc.crc32Hex(string.rep("a", 1000)), "9a38da03", "CRC32 multi-block")
  end,

  ["streaming extend matches one-shot"] = function(): void
    local data: string = "The quick brown fox jumps over the lazy dog"
    T.eq(crc.crc32Extend(crc.crc32Extend(0, "The quick "), "brown fox jumps over the lazy dog"),
      crc.crc32(data), "CRC32 streaming")
    T.eq(crc.crc32cExtend(crc.crc32cExtend(0, "The quick "), "brown fox jumps over the lazy dog"),
      crc.crc32c(data), "CRC32C streaming")
    T.eq(crc.crc32(""), 0, "empty CRC32 integer")
    T.eq(crc.crc32c(""), 0, "empty CRC32C integer")
  end,

  ["LevelDB mask is reversible"] = function(): void
    local values: integer[] = { 0, 1, 123456789, 4294967295 }
    for i: integer = 1, #values do
      local value: integer = values[i]
      T.eq(crc.crc32cUnmask(crc.crc32cMask(value)), value, "mask round-trip")
    end
    T.ok(crc.crc32cMask(0) ~= 0, "zero is masked")
  end,

  ["binary payloads"] = function(): void
    local data: string = "\0\1\2\255\254\253"
    T.eq(#crc.crc32Hex(data), 8, "hex width")
    T.eq(crc.crc32cExtend(0, data), crc.crc32c(data), "binary extend")
  end,
}
