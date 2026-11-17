import T from "tlua_test"
import set from "../set"
import lists from "../lists"

local function sorted(setValue: any): string
  return table.concat(lists.sortStrings(setValue:values(), false), ",")
end

return {
  ["add, has, remove, size and clear"] = function(): void
    local s = set.Set.new<string>()
    T.ok(s:isEmpty(), "empty")
    T.ok(s:add("a"), "add a")
    T.ok(not s:add("a"), "duplicate add")
    T.ok(s:add("b"), "add b")
    T.eq(s:size(), 2, "size")
    T.ok(s:has("a"), "has a")
    T.ok(s:contains("b"), "contains b")
    T.ok(not s:has("c"), "missing")
    T.ok(s:remove("a"), "remove a")
    T.ok(not s:remove("a"), "remove missing")
    T.eq(s:size(), 1, "size after remove")
    T.eq(sorted(s), "b", "values")
    s:clear()
    T.ok(s:isEmpty(), "clear")
    T.eq(#s:values(), 0, "empty values")
  end,

  ["union, intersection, difference and subset"] = function(): void
    local a = set.from<string>({ "a", "b", "c" })
    local b = set.from<string>({ "b", "c", "d" })
    T.eq(sorted(a:union(b)), "a,b,c,d", "union")
    T.eq(sorted(a:intersection(b)), "b,c", "intersection")
    T.eq(sorted(a:difference(b)), "a", "difference")
    T.eq(sorted(b:difference(a)), "d", "difference reverse")
    T.ok(a:isSubsetOf(a:union(b)), "subset of union")
    T.ok(not a:isSubsetOf(b), "not subset")
    T.ok(a:equals(a:clone()), "clone equals")
    T.ok(not a:equals(b), "not equals")
    T.eq(sorted(a), "a,b,c", "inputs untouched")
  end,

  ["forEach and empty sets"] = function(): void
    local s = set.from<integer>({ 1, 2, 3 })
    local total: integer = 0
    s:forEach(function(value: integer): void total = total + value end)
    T.eq(total, 6, "forEach")
    local emptyA = set.Set.new<string>()
    local emptyB = set.Set.new<string>()
    T.ok(emptyA:equals(emptyB), "empty equals")
    T.ok(emptyA:isSubsetOf(emptyB), "empty subset")
    T.eq(emptyA:size(), 0, "empty size")
    T.eq(#emptyA:union(emptyB):values(), 0, "empty union")
    T.eq(#emptyA:intersection(emptyB):values(), 0, "empty intersection")
  end,
}
