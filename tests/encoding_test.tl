import T from "tlua_test"
import encoding from "../encoding"

return {
  ["Base64 vectors and round-trip"] = function(): void
    T.eq(encoding.base64Encode(""), "", "empty")
    T.eq(encoding.base64Encode("f"), "Zg==", "one")
    T.eq(encoding.base64Encode("fo"), "Zm8=", "two")
    T.eq(encoding.base64Encode("foo"), "Zm9v", "three")
    T.eq(encoding.base64Encode("foobar"), "Zm9vYmFy", "six")
    T.eq(encoding.base64Decode("Zg==").data, "f", "decode one")
    T.eq(encoding.base64Decode("Zm8=").data, "fo", "decode two")
    T.eq(encoding.base64Decode("Zm9vYmFy").data, "foobar", "decode six")
    T.eq(encoding.base64Decode("Zg").data, "f", "unpadded decode")
    T.eq(encoding.base64Decode("Zm8").data, "fo", "unpadded decode two")
    local binary: string = "\0\1\2\255\254\253"
    T.eq(encoding.base64Decode(encoding.base64Encode(binary)).data, binary, "binary round-trip")
    T.ok(encoding.base64Decode("!!!!").ok == false, "invalid chars")
    T.ok(encoding.base64Decode("A").ok == false, "invalid length")
    T.ok(encoding.base64Decode("Zg=").ok == false, "bad padding")
    T.ok(encoding.base64Decode("Zg===").ok == false, "too much padding")
    T.ok(encoding.base64Decode("AB==").ok == false, "non-canonical trailing bits")
    T.ok(encoding.base64Decode("A===").ok == false, "bad padding shape")
    T.ok(encoding.base64Decode("-_-_").ok == false, "standard rejects URL alphabet")
  end,

  ["Base64URL"] = function(): void
    local binary: string = "\255\254\253\252"
    local encoded: string = encoding.base64UrlEncode(binary)
    T.eq(encoded, "__79_A", "url encode")
    T.eq(encoding.base64UrlDecode(encoded).data, binary, "url round-trip")
    T.ok(encoding.base64UrlDecode("Zg==").ok == false, "url rejects padding")
    T.ok(encoding.base64UrlDecode("+").ok == false, "url rejects plus")
    T.ok(encoding.base64UrlDecode("+/+/").ok == false, "url rejects standard alphabet")
  end,

  ["hex"] = function(): void
    T.eq(encoding.hexEncode("\0\1\15\16\255"), "00010f10ff", "hex lower")
    T.eq(encoding.hexEncodeUpper("\0\1\15\16\255"), "00010F10FF", "hex upper")
    T.eq(encoding.hexDecode("00010f10ff").data, "\0\1\15\16\255", "hex decode")
    T.ok(encoding.hexDecode("0").ok == false, "odd hex")
    T.ok(encoding.hexDecode("zz").ok == false, "invalid hex")
    T.eq(encoding.hexDecode("").data, "", "empty hex")
  end,

  ["percent and form encoding"] = function(): void
    T.eq(encoding.percentEncode("a b/c?d=e&f"), "a%20b%2Fc%3Fd%3De%26f", "percent encode")
    T.eq(encoding.percentEncode("-_.~"), "-_.~", "unreserved")
    T.eq(encoding.percentEncode("\255"), "%FF", "binary percent")
    T.eq(encoding.percentDecode("a%20b%2Fc").data, "a b/c", "percent decode")
    T.eq(encoding.percentDecode("a+b").data, "a+b", "plus is literal")
    T.ok(encoding.percentDecode("%").ok == false, "truncated percent")
    T.ok(encoding.percentDecode("%2").ok == false, "short percent")
    T.ok(encoding.percentDecode("%ZZ").ok == false, "bad percent")
    T.eq(encoding.formEncode("a b+c"), "a+b%2Bc", "form encode")
    T.eq(encoding.formDecode("a+b%2Bc").data, "a b+c", "form decode")
    T.eq(encoding.urlEncode("a b"), "a%20b", "url alias")
    T.eq(encoding.urlDecode("a%20b").data, "a b", "url decode alias")
  end,
}
