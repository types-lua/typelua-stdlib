import T from "tlua_test"
import path from "../path"

local function joined(items: string[]): string
  return table.concat(items, ",")
end

return {
  ["absolute and normalization"] = function(): void
    T.ok(path.isAbsolute("/a"), "absolute")
    T.ok(not path.isAbsolute("a"), "relative")
    T.ok(not path.isAbsolute(""), "empty relative")
    T.eq(path.normalize(""), ".", "empty normalize")
    T.eq(path.normalize("."), ".", "dot")
    T.eq(path.normalize("./"), ".", "dot slash")
    T.eq(path.normalize("a//b"), "a/b", "duplicate slash")
    T.eq(path.normalize("/a/../b"), "/b", "parent")
    T.eq(path.normalize("a/../../b"), "../b", "relative parent")
    T.eq(path.normalize("../a"), "../a", "leading parent")
    T.eq(path.normalize("/.."), "/", "root parent")
    T.eq(path.normalize("a/.."), ".", "cancel")
    T.eq(path.normalize("//a///b//"), "/a/b", "absolute duplicate")
    T.eq(path.normalize("a/./b/."), "a/b", "dots removed")
  end,

  ["join"] = function(): void
    T.eq(path.join({}), ".", "empty join")
    T.eq(path.join({ "a", "b" }), "a/b", "join")
    T.eq(path.join({ "a", "", "b" }), "a/b", "empty segment")
    T.eq(path.join({ "/a", "b" }), "/a/b", "absolute join")
    T.eq(path.join({ "a", "../b" }), "b", "normalized join")
    T.eq(path.join({ "a", "/b" }), "a/b", "inner absolute segment")
  end,

  ["dirname and basename"] = function(): void
    T.eq(path.dirname(""), ".", "dirname empty")
    T.eq(path.dirname("/"), "/", "dirname root")
    T.eq(path.dirname("/a"), "/", "dirname absolute")
    T.eq(path.dirname("a/b"), "a", "dirname relative")
    T.eq(path.dirname("a/b/"), "a", "dirname trailing slash")
    T.eq(path.dirname("a//b"), "a", "dirname duplicate slash")
    T.eq(path.dirname("a"), ".", "dirname leaf")
    T.eq(path.basename(""), "", "basename empty")
    T.eq(path.basename("/"), "", "basename root")
    T.eq(path.basename("/a/b/"), "b", "basename trailing")
    T.eq(path.basename("a"), "a", "basename relative")
    T.eq(path.basename("a/b.txt"), "b.txt", "basename file")
  end,

  ["extension, stem and parse"] = function(): void
    T.eq(path.extname("a.txt"), ".txt", "ext")
    T.eq(path.extname("a.tar.gz"), ".gz", "last ext")
    T.eq(path.extname(".bashrc"), "", "dotfile ext")
    T.eq(path.extname("a"), "", "no ext")
    T.eq(path.extname("a."), ".", "trailing dot")
    T.eq(path.stem("a.tar.gz"), "a.tar", "stem")
    T.eq(path.stem(".bashrc"), ".bashrc", "dotfile stem")
    local parsed = path.parse("/a/b.tar.gz")
    T.eq(parsed.root, "/", "parse root")
    T.eq(parsed.dir, "/a", "parse dir")
    T.eq(parsed.base, "b.tar.gz", "parse base")
    T.eq(parsed.ext, ".gz", "parse ext")
    T.eq(parsed.name, "b.tar", "parse name")
    local relative = path.parse("b.txt")
    T.eq(relative.root, "", "relative root")
    T.eq(relative.dir, "", "relative dir")
  end,

  ["segments and containment"] = function(): void
    T.eq(joined(path.segments("/a/b/c")), "a,b,c", "segments")
    T.eq(joined(path.segments(".")), "", "empty segments")
    T.eq(joined(path.segments("../a")), "..,a", "parent segments")
    T.ok(path.isWithin("/a/b", "/a/b/c"), "within child")
    T.ok(path.isWithin("/a/b", "/a/b"), "within self")
    T.ok(not path.isWithin("/a/b", "/a/bc"), "prefix is not containment")
    T.ok(not path.isWithin("/a/b", "/a"), "parent is not within")
    T.ok(path.isWithin(".", "a/b"), "relative root")
    T.ok(not path.isWithin("/a", "a"), "absolute vs relative")
    T.ok(not path.isWithin(".", "../x"), "relative escape")
    T.ok(not path.isWithin("..", "../.."), "parent escape")
    T.ok(path.isWithin("../a", "../a/b"), "parent child")
  end,

  ["relative paths"] = function(): void
    T.eq(path.relative("/a/b", "/a/c"), "../c", "sibling")
    T.eq(path.relative("/a/b", "/a/b"), ".", "same")
    T.eq(path.relative("/a/b/c", "/a"), "../..", "up")
    T.eq(path.relative("a/b", "a/c"), "../c", "relative input")
    T.raises(function(): void path.relative("/a", "b") end)
  end,

  ["extensions and separators"] = function(): void
    T.eq(path.withExtension("a.txt", "md"), "a.md", "replace ext")
    T.eq(path.withExtension("a", ".md"), "a.md", "add ext")
    T.eq(path.withExtension("a.tar.gz", "zip"), "a.tar.zip", "last ext")
    T.eq(path.removeExtension("a.txt"), "a", "remove ext")
    T.eq(path.removeExtension("a"), "a", "remove missing")
    T.eq(path.toPosix("a\\b\\c"), "a/b/c", "toPosix")
  end,
}
