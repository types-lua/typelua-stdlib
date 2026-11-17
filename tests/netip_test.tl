import T from "tlua_test"
import netip from "../netip"

local function roundTrip(text: string): string
  local result = netip.parse(text)
  T.ok(result.ok, "parse " .. text)
  return netip.format(result.ip!)
end

return {
  ["IPv4 parsing and formatting"] = function(): void
    T.eq(roundTrip("0.0.0.0"), "0.0.0.0", "zero")
    T.eq(roundTrip("127.0.0.1"), "127.0.0.1", "loopback")
    T.eq(roundTrip("192.168.1.255"), "192.168.1.255", "private end")
    T.eq(roundTrip("255.255.255.255"), "255.255.255.255", "broadcast")
    T.ok(not netip.parse("1.2.3").ok, "three octets")
    T.ok(not netip.parse("1.2.3.4.5").ok, "five octets")
    T.ok(not netip.parse("1.2.3.256").ok, "range")
    T.ok(not netip.parse("01.2.3.4").ok, "leading zero")
    T.ok(not netip.parse("a.b.c.d").ok, "non-numeric")
    T.ok(not netip.parse(string.rep("1", 300)).ok, "length limit")
    T.ok(not netip.parseCidr(string.rep("1", 300) .. "/24").ok, "cidr length limit")
    T.ok(netip.isV4(netip.parse("1.2.3.4").ip!), "isV4")
    T.ok(not netip.isV6(netip.parse("1.2.3.4").ip!), "not v6")
  end,

  ["IPv6 parsing, compression and IPv4 embedding"] = function(): void
    T.eq(roundTrip("::"), "::", "unspecified")
    T.eq(roundTrip("::1"), "::1", "loopback")
    T.eq(roundTrip("2001:db8::1"), "2001:db8::1", "compressed")
    T.eq(
      roundTrip("2001:0db8:0000:0000:0000:ff00:0042:8329"),
      "2001:db8::ff00:42:8329",
      "canonical"
    )
    T.eq(roundTrip("1:2:3:4:5:6:7:8"), "1:2:3:4:5:6:7:8", "full")
    T.eq(roundTrip("::ffff:192.0.2.1"), "::ffff:c000:201", "embedded IPv4")
    T.eq(roundTrip("2001:db8:0:1:1:1:1:1"), "2001:db8:0:1:1:1:1:1", "single zero")
    T.ok(not netip.parse("1::2::3").ok, "multiple compression")
    T.ok(not netip.parse("1:2:3:4:5:6:7").ok, "too few groups")
    T.ok(not netip.parse("1:2:3:4:5:6:7:8:9").ok, "too many groups")
    T.ok(not netip.parse("gggg::1").ok, "bad hex")
    T.ok(not netip.parse("fe80::1%eth0").ok, "zone rejected")
    T.ok(not netip.parse("::ffff:192.0.2.999").ok, "bad embedded IPv4")
    T.ok(netip.isV6(netip.parse("::1").ip!), "isV6")
  end,

  ["CIDR network and containment"] = function(): void
    local cidr = netip.parseCidr("192.168.1.0/24")
    T.ok(cidr.ok, "v4 cidr")
    T.eq(netip.formatCidr(cidr.cidr!), "192.168.1.0/24", "cidr format")
    T.eq(netip.format(netip.network(cidr.cidr!)), "192.168.1.0", "network")
    T.ok(netip.containsText(cidr.cidr!, "192.168.1.42"), "inside")
    T.ok(not netip.containsText(cidr.cidr!, "192.168.2.1"), "outside")
    T.ok(not netip.containsText(cidr.cidr!, "10.0.0.1"), "other")
    T.ok(netip.containsText(netip.parseCidr("0.0.0.0/0").cidr!, "203.0.113.9"), "default route")
    T.ok(netip.containsText(netip.parseCidr("10.0.0.0/8").cidr!, "10.255.255.255"), "edge")
    T.ok(not netip.containsText(netip.parseCidr("10.0.0.0/8").cidr!, "11.0.0.1"), "outside edge")
    local v6 = netip.parseCidr("2001:db8::/32")
    T.ok(v6.ok, "v6 cidr")
    T.eq(netip.format(netip.network(v6.cidr!)), "2001:db8::", "v6 network")
    T.ok(netip.containsText(v6.cidr!, "2001:db8::1"), "v6 inside")
    T.ok(not netip.containsText(v6.cidr!, "2001:db9::1"), "v6 outside")
    T.ok(not netip.containsText(cidr.cidr!, "::1"), "cross family")
    T.ok(not netip.parseCidr("192.168.1.1/33").ok, "v4 prefix range")
    T.ok(not netip.parseCidr("2001:db8::1/129").ok, "v6 prefix range")
    T.ok(not netip.parseCidr("192.168.1.1").ok, "missing prefix")
    local nonAligned = netip.parseCidr("10.0.0.0/9")
    T.eq(netip.format(netip.network(nonAligned.cidr!)), "10.0.0.0", "non-aligned network")
    T.ok(netip.containsText(nonAligned.cidr!, "10.127.0.1"), "non-aligned inside")
    T.ok(not netip.containsText(nonAligned.cidr!, "10.128.0.1"), "non-aligned outside")
    local partial = netip.parseCidr("192.168.1.130/25")
    T.eq(netip.format(netip.network(partial.cidr!)), "192.168.1.128", "partial network")
    T.ok(netip.containsText(partial.cidr!, "192.168.1.200"), "partial inside")
    T.ok(not netip.containsText(partial.cidr!, "192.168.1.100"), "partial outside")
    local v6Partial = netip.parseCidr("2001:db8::/65")
    T.ok(netip.containsText(v6Partial.cidr!, "2001:db8::1"), "v6 partial inside")
    T.ok(not netip.containsText(v6Partial.cidr!, "2001:db8:0:0:8000::1"), "v6 partial outside")
  end,

  ["address classification"] = function(): void
    T.ok(netip.isPrivate(netip.parse("10.0.0.1").ip!), "10/8")
    T.ok(netip.isPrivate(netip.parse("172.16.0.1").ip!), "172.16")
    T.ok(netip.isPrivate(netip.parse("172.31.255.1").ip!), "172.31")
    T.ok(not netip.isPrivate(netip.parse("172.32.0.1").ip!), "172.32")
    T.ok(netip.isPrivate(netip.parse("192.168.0.1").ip!), "192.168")
    T.ok(not netip.isPrivate(netip.parse("8.8.8.8").ip!), "public")
    T.ok(netip.isLoopback(netip.parse("127.0.0.1").ip!), "v4 loopback")
    T.ok(netip.isLoopback(netip.parse("::1").ip!), "v6 loopback")
    T.ok(netip.isLinkLocal(netip.parse("169.254.1.1").ip!), "v4 link local")
    T.ok(netip.isLinkLocal(netip.parse("fe80::1").ip!), "v6 link local")
    T.ok(netip.isMulticast(netip.parse("224.0.0.1").ip!), "v4 multicast")
    T.ok(netip.isMulticast(netip.parse("ff02::1").ip!), "v6 multicast")
    T.ok(netip.isUnspecified(netip.parse("0.0.0.0").ip!), "v4 unspecified")
    T.ok(netip.isUnspecified(netip.parse("::").ip!), "v6 unspecified")
    T.ok(netip.isPrivate(netip.parse("fc00::1").ip!), "v6 unique local")
    local mappedLoopback = netip.parse("::ffff:127.0.0.1").ip!
    local mappedPrivate = netip.parse("::ffff:10.0.0.1").ip!
    local mappedPublic = netip.parse("::ffff:8.8.8.8").ip!
    T.ok(netip.isV4Mapped(mappedLoopback), "v4-mapped")
    T.eq(netip.format(netip.mappedV4(mappedLoopback)!), "127.0.0.1", "mappedV4")
    T.ok(netip.isLoopback(mappedLoopback), "mapped loopback")
    T.ok(netip.isPrivate(mappedPrivate), "mapped private")
    T.ok(not netip.isPrivate(mappedPublic), "mapped public")
    T.ok(netip.isLinkLocal(netip.parse("::ffff:169.254.1.1").ip!), "mapped link local")
    T.ok(netip.isMulticast(netip.parse("::ffff:224.0.0.1").ip!), "mapped multicast")
    T.ok(netip.isUnspecified(netip.parse("::ffff:0.0.0.0").ip!), "mapped unspecified")
  end,
}
