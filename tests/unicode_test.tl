import T from "tlua_test"
import unicode from "../unicode"

return {
  ["valid ASCII and multi-byte codepoints"] = function(): void
    T.ok(unicode.valid("hello"), "ascii valid")
    local decoded = unicode.decode("a" .. string.char(0xC3, 0xA9) .. "b")
    T.ok(decoded.ok, "decode ok")
    T.eq(#decoded.codepoints, 3, "codepoint count")
    T.eq(decoded.codepoints[1], 97, "a")
    T.eq(decoded.codepoints[2], 233, "e acute")
    T.eq(decoded.codepoints[3], 98, "b")
    local emoji = unicode.decode(string.char(0xF0, 0x9F, 0x98, 0x80))
    T.eq(emoji.codepoints[1], 128512, "emoji")
    T.eq(unicode.encode({ 97, 233, 128512 }).text,
      "a" .. string.char(0xC3, 0xA9) .. string.char(0xF0, 0x9F, 0x98, 0x80),
      "encode")
    T.eq(unicode.char(0), string.char(0), "NUL")
  end,

  ["strict validation"] = function(): void
    T.ok(not unicode.valid(string.char(0xC0, 0x80)), "overlong 2")
    T.ok(not unicode.valid(string.char(0xE0, 0x80, 0x80)), "overlong 3")
    T.ok(not unicode.valid(string.char(0xF0, 0x80, 0x80, 0x80)), "overlong 4")
    T.ok(not unicode.valid(string.char(0xED, 0xA0, 0x80)), "surrogate")
    T.ok(not unicode.valid(string.char(0xF4, 0x90, 0x80, 0x80)), "above max")
    T.ok(not unicode.valid(string.char(0xC3)), "truncated")
    T.ok(not unicode.valid(string.char(0xC3, 0x28)), "bad continuation")
    T.ok(not unicode.valid(string.char(0xFF)), "bad lead")
    T.ok(not unicode.decode(string.char(0xC3)).ok, "decode error")
  end,

  ["length, codepointAt and encode errors"] = function(): void
    T.eq(unicode.length("hello").length, 5, "length ascii")
    T.eq(unicode.length("a" .. string.char(0xC3, 0xA9)).length, 2, "length unicode")
    T.ok(not unicode.length(string.char(0xFF)).ok, "length invalid")
    local at = unicode.codepointAt("a" .. string.char(0xC3, 0xA9), 2)
    T.ok(at.ok, "codepointAt ok")
    T.eq(at.codepoint, 233, "codepointAt value")
    T.ok(not unicode.codepointAt("a", 2).ok, "codepointAt range")
    T.raises(function(): void unicode.char(-1) end)
    T.raises(function(): void unicode.char(0xD800) end)
    T.raises(function(): void unicode.char(0x110000) end)
    T.ok(not unicode.encode({ 0xD800 }).ok, "encode surrogate")
    T.ok(not unicode.encode({ 0x110000 }).ok, "encode above max")
    T.eq(unicode.encode({}).text, "", "encode empty")
  end,
}
