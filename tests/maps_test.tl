import T from "tlua_test"
import maps from "../maps"
import lists from "../lists"

local function sortedKeys(m: map<string, integer>): string
  return table.concat(lists.sortStrings(maps.keys<string, integer>(m), false), ",")
end

return {
  ["keys, values, entries and fromEntries"] = function(): void
    local m: map<string, integer> = { b = 2, a = 1, c = 3 }
    T.eq(sortedKeys(m), "a,b,c", "keys")
    T.eq(lists.sortNumbers(maps.values<string, integer>(m), false)[1], 1, "values")
    local entries = maps.entries<string, integer>(m)
    T.eq(#entries, 3, "entries count")
    local rebuilt: map<string, integer> = maps.fromEntries<string, integer>(entries)
    T.ok(maps.equals<string, integer>(m, rebuilt), "fromEntries")
    T.eq(#maps.toArray<string, integer>(m), 3, "toArray")
    T.eq(maps.count<string, integer>(m), 3, "count")
    T.ok(not maps.isEmpty<string, integer>(m), "not empty")
    T.ok(maps.isEmpty<string, integer>({}), "empty")
  end,

  ["get, set, has and remove"] = function(): void
    local m: map<string, integer> = { a = 1 }
    T.ok(maps.has<string, integer>(m, "a"), "has")
    T.ok(not maps.has<string, integer>(m, "b"), "not has")
    T.eq(maps.get<string, integer>(m, "a", 0), 1, "get")
    T.eq(maps.get<string, integer>(m, "b", 0), 0, "fallback")
    T.eq(maps.getOrNil<string, integer>(m, "b"), nil, "getOrNil")
    maps.set<string, integer>(m, "b", 2)
    T.eq(m["b"], 2, "set")
    T.eq(maps.remove<string, integer>(m, "a"), 1, "remove")
    T.ok(not maps.has<string, integer>(m, "a"), "removed")
    T.eq(maps.remove<string, integer>(m, "missing"), nil, "remove missing")
  end,

  ["clone, merge and mergeInto"] = function(): void
    local first: map<string, integer> = { a = 1, b = 2 }
    local second: map<string, integer> = { b = 20, c = 3 }
    local cloned: map<string, integer> = maps.clone<string, integer>(first)
    T.ok(maps.equals<string, integer>(first, cloned), "clone values")
    cloned["a"] = 99
    T.eq(first["a"], 1, "clone independent")
    local merged: map<string, integer> = maps.merge<string, integer>(first, second)
    T.eq(merged["b"], 20, "merge override")
    T.eq(merged["c"], 3, "merge new")
    T.eq(first["b"], 2, "merge input untouched")
    local target: map<string, integer> = { x = 1 }
    maps.mergeInto<string, integer>(target, second)
    T.eq(target["x"], 1, "mergeInto keeps")
    T.eq(target["b"], 20, "mergeInto adds")
  end,

  ["pick, omit and invert"] = function(): void
    local m: map<string, integer> = { a = 1, b = 2, c = 3 }
    local picked: map<string, integer> = maps.pick<string, integer>(m, { "a", "c", "missing" })
    T.eq(sortedKeys(picked), "a,c", "pick")
    local omitted: map<string, integer> = maps.omit<string, integer>(m, { "b" })
    T.eq(sortedKeys(omitted), "a,c", "omit")
    local inverted: map<string, string> = maps.invert({ a = "x", b = "y" })
    T.eq(inverted["x"], "a", "invert")
    T.eq(inverted["y"], "b", "invert second")
    local duplicate = pcall(function(): void maps.invert({ a = "x", b = "x" }) end)
    T.ok(not duplicate, "invert duplicate value")
  end,

  ["mapValues, filter, forEach, equals and clear"] = function(): void
    local m: map<string, integer> = { a = 1, b = 2, c = 3 }
    local doubled: map<string, integer> = maps.mapValues<string, integer, integer>(
      m,
      function(value: integer, _key: string): integer return value * 2 end
    )
    T.eq(doubled["a"], 2, "mapValues")
    local even: map<string, integer> = maps.filter<string, integer>(
      m,
      function(_key: string, value: integer): boolean return value % 2 == 0 end
    )
    T.eq(maps.count<string, integer>(even), 1, "filter count")
    T.eq(even["b"], 2, "filter value")
    local total: integer = 0
    maps.forEach<string, integer>(m, function(_key: string, value: integer): void
      total = total + value
    end)
    T.eq(total, 6, "forEach")
    T.ok(maps.equals<string, integer>({ a = 1 }, { a = 1 }), "equals")
    T.ok(not maps.equals<string, integer>({ a = 1 }, { a = 2 }), "equals value")
    T.ok(not maps.equals<string, integer>({ a = 1 }, { a = 1, b = 2 }), "equals size")
    maps.clear<string, integer>(m)
    T.ok(maps.isEmpty<string, integer>(m), "clear")
  end,
}
