import T from "tlua_test"
import hash from "../hash"
import bits from "../bitops"

local function repeatByte(byte: integer, count: integer): string
  local out: string[] = {}
  for _: integer = 1, count do out[#out + 1] = string.char(byte) end
  return table.concat(out)
end

return {
  ["32-bit bit operations"] = function(): void
    T.eq(bits.band(0xF0F0, 0xFF00), 0xF000, "and")
    T.eq(bits.bor(0xF000, 0x00F0), 0xF0F0, "or")
    T.eq(bits.bxor(0xFFFF, 0x0F0F), 0xF0F0, "xor")
    T.eq(bits.bnot(0), 4294967295, "not")
    T.eq(bits.lshift(1, 31), 2147483648, "left shift")
    T.eq(bits.rshift(2147483648, 31), 1, "right shift")
    T.eq(bits.rotl(0x80000001, 1), 3, "rotate left")
    T.eq(bits.rotr(3, 1), 0x80000001, "rotate right")
    T.eq(bits.add(4294967295, 1), 0, "wrap add")
  end,

  ["SHA-1 vectors"] = function(): void
    T.eq(hash.sha1Hex(""), "da39a3ee5e6b4b0d3255bfef95601890afd80709", "empty")
    T.eq(hash.sha1Hex("abc"), "a9993e364706816aba3e25717850c26c9cd0d89d", "abc")
    T.eq(
      hash.sha1Hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
      "84983e441c3bd26ebaae4aa1f95129e5e54670f1",
      "long"
    )
    T.eq(hash.sha1Hex(string.rep("a", 1000)), "291e9a6c66994949b57ba5e650361e98fc36b1ba", "1000 a")
  end,

  ["SHA-256 vectors"] = function(): void
    T.eq(hash.sha256Hex(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "empty")
    T.eq(hash.sha256Hex("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "abc")
    T.eq(
      hash.sha256Hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
      "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
      "long"
    )
    T.eq(
      hash.sha256Hex(string.rep("a", 1000)),
      "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3",
      "1000 a"
    )
  end,

  ["HMAC-SHA256 RFC 4231 vectors"] = function(): void
    local key1: string = repeatByte(0x0B, 20)
    T.eq(
      hash.hmacSha256Hex(key1, "Hi There"),
      "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
      "case 1"
    )
    T.eq(
      hash.hmacSha256Hex("Jefe", "what do ya want for nothing?"),
      "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
      "case 2"
    )
    local key3: string = repeatByte(0xAA, 20)
    local data3: string = repeatByte(0xDD, 50)
    T.eq(
      hash.hmacSha256Hex(key3, data3),
      "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe",
      "case 3"
    )
    T.eq(#hash.hmacSha256("k", "d"), 32, "raw HMAC length")
    local longKey: string = repeatByte(0xAA, 131)
    T.eq(
      hash.hmacSha256Hex(longKey, "Test Using Larger Than Block-Size Key - Hash Key First"),
      "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
      "long key"
    )
  end,

  ["constant-time comparison"] = function(): void
    T.ok(hash.constantTimeEqual("abc", "abc"), "equal")
    T.ok(not hash.constantTimeEqual("abc", "abd"), "different")
    T.ok(not hash.constantTimeEqual("abc", "ab"), "length")
    T.ok(hash.constantTimeEqual("", ""), "empty")
  end,
}
