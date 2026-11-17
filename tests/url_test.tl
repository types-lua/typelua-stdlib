import T from "tlua_test"
import url from "../url"

return {
  ["parse absolute URLs"] = function(): void
    local result = url.parse("http://user:pass@example.com:8080/a/b?x=1&y=2#frag")
    T.ok(result.ok, "parse ok")
    local p = result.parts!
    T.eq(p.scheme, "http", "scheme")
    T.eq(p.username, "user", "username")
    T.eq(p.password, "pass", "password")
    T.eq(p.host, "example.com", "host")
    T.eq(p.port, 8080, "port")
    T.ok(p.hasPort, "has port")
    T.eq(p.path, "/a/b", "path")
    T.eq(p.query, "x=1&y=2", "query")
    T.eq(p.fragment, "frag", "fragment")
    T.eq(url.format(p), "http://user:pass@example.com:8080/a/b?x=1&y=2#frag", "format")
    local plain = url.parse("https://example.com")
    T.ok(plain.ok, "plain ok")
    T.eq(plain.parts!.path, "", "empty path")
    T.eq(url.format(plain.parts!), "https://example.com", "plain format")
    local empty = url.parse("https://example.com/?#")
    T.ok(empty.ok, "empty query fragment")
    T.ok(empty.parts!.hasQuery, "has query")
    T.ok(empty.parts!.hasFragment, "has fragment")
    T.eq(url.format(empty.parts!), "https://example.com/?#", "empty format")
    local mailto = url.parse("mailto:user@example.com")
    T.ok(mailto.ok, "mailto")
    T.ok(not mailto.parts!.hasAuthority, "no authority")
    T.eq(url.format(mailto.parts!), "mailto:user@example.com", "mailto format")
    local fragmentOnly = url.parse("http://host#frag")
    T.ok(fragmentOnly.ok, "fragment-only host")
    T.eq(fragmentOnly.parts!.host, "host", "fragment host")
    T.eq(fragmentOnly.parts!.fragment, "frag", "fragment value")
    T.eq(url.format(fragmentOnly.parts!), "http://host#frag", "fragment format")
  end,

  ["IPv6 and ports"] = function(): void
    local result = url.parse("http://[::1]:443/a")
    T.ok(result.ok, "ipv6 ok")
    T.eq(result.parts!.host, "::1", "ipv6 host")
    T.eq(result.parts!.port, 443, "ipv6 port")
    T.eq(url.format(result.parts!), "http://[::1]:443/a", "ipv6 format")
    local noPort = url.parse("http://[2001:db8::1]/")
    T.ok(noPort.ok, "ipv6 no port")
    T.eq(url.format(noPort.parts!), "http://[2001:db8::1]/", "ipv6 no port format")
    local portZero = url.parse("http://host:0/")
    T.ok(portZero.ok, "port zero")
    T.eq(url.format(portZero.parts!), "http://host:0/", "port zero format")
    T.ok(not url.parse("http://host:65536/").ok, "port too large")
    T.ok(not url.parse("http://host:abc/").ok, "port not numeric")
    T.ok(not url.parse("http://host:/").ok, "empty port")
  end,

  ["reject malformed URLs"] = function(): void
    T.ok(not url.parse("").ok, "empty")
    T.ok(not url.parse("example.com").ok, "no scheme")
    T.ok(not url.parse("1http://x").ok, "invalid scheme start")
    T.ok(not url.parse("ht tp://x").ok, "space")
    T.ok(not url.parse("http://host/a b").ok, "space path")
    T.ok(not url.parse("http://host/\n").ok, "control")
    T.ok(not url.parse("http://").ok, "empty host")
    T.ok(not url.parse("http:///path").ok, "empty authority host")
    T.ok(not url.parse("http://[::1").ok, "unterminated IPv6")
    T.ok(not url.parse("http://[::1]x").ok, "junk after IPv6")
    T.ok(not url.parse("http://::1/").ok, "unbracketed IPv6")
    T.ok(not url.parse("http:").ok, "empty path without authority")
  end,

  ["query parsing and building"] = function(): void
    local result = url.parseQuery("a=1&b=two+words&c=%2F&a=last")
    T.ok(result.ok, "query ok")
    T.eq(result.values["a"], "last", "duplicate last")
    T.eq(result.values["b"], "two words", "plus")
    T.eq(result.values["c"], "/", "percent")
    local empty = url.parseQuery("")
    T.ok(empty.ok, "empty query")
    T.eq(url.buildQuery({}), "", "empty build")
    local built = url.buildQuery({ b = "two words", a = "1" })
    T.eq(built, "a=1&b=two+words", "deterministic build")
    T.ok(not url.parseQuery("a=%ZZ").ok, "bad escape")
    T.eq(url.parseQuery("flag").values["flag"], "", "flag")
  end,

  ["length limits"] = function(): void
    T.ok(not url.parseWith("http://example.com", { maxLength = 3 }).ok, "max length")
    T.raises(function(): void url.parseWith("http://x", { maxLength = 0 }) end)
  end,
}
