import T from "tlua_test"
import semver from "../semver"

return {
  ["parse and format"] = function(): void
    local basic = semver.parse("1.2.3")
    T.ok(basic.ok, "basic ok")
    T.eq(basic.version!.major, 1, "major")
    T.eq(basic.version!.minor, 2, "minor")
    T.eq(basic.version!.patch, 3, "patch")
    T.eq(#basic.version!.prerelease, 0, "no prerelease")
    T.eq(#basic.version!.build, 0, "no build")
    local full = semver.parse("1.0.0-alpha.1+build.007")
    T.ok(full.ok, "full ok")
    T.eq(full.version!.prerelease[1], "alpha", "pre alpha")
    T.eq(full.version!.prerelease[2], "1", "pre numeric")
    T.eq(full.version!.build[2], "007", "build leading zero allowed")
    T.eq(semver.format(full.version!), "1.0.0-alpha.1+build.007", "format")
    T.ok(semver.isValid("0.0.0"), "zero")
  end,

  ["precedence ordering"] = function(): void
    local ordered: string[] = {
      "1.0.0-alpha",
      "1.0.0-alpha.1",
      "1.0.0-alpha.beta",
      "1.0.0-beta",
      "1.0.0-beta.2",
      "1.0.0-beta.11",
      "1.0.0-rc.1",
      "1.0.0",
    }
    for i: integer = 2, #ordered do
      T.ok(semver.compareText(ordered[i - 1], ordered[i]) < 0,
        ordered[i - 1] .. " < " .. ordered[i])
    end
    T.ok(semver.compareText("2.0.0", "10.0.0") < 0, "numeric core")
    T.ok(semver.compareText("1.0.0-1", "1.0.0-alpha") < 0, "numeric pre before alpha")
    T.eq(semver.compareText("1.0.0+a", "1.0.0+b"), 0, "build ignored")
    T.eq(semver.compareText("1.2.3", "1.2.3"), 0, "equal")
    T.ok(semver.compareText("1.0.0-99999999999999999999", "1.0.0-100000000000000000000") < 0,
      "large numeric prerelease by length")
  end,

  ["invalid versions"] = function(): void
    local invalid: string[] = {
      "", "1", "1.2", "1.2.3.4",
      "01.2.3", "1.02.3", "1.2.03",
      "1.2.3-", "1.2.3+", "1.2.3-01",
      "1.2.3-a_b", "1.2.3+a_b", "v1.2.3",
      "1.2.3-", "1.2.3+build+again",
      "9007199254740992.0.0",
    }
    for i: integer = 1, #invalid do
      T.ok(not semver.parse(invalid[i]).ok, "invalid: " .. invalid[i])
    end
    T.raises(function(): void semver.compareText("bad", "1.0.0") end)
    T.raises(function(): void semver.compareText("1.0.0", "bad") end)
  end,
}
