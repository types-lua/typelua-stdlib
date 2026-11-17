import T from "tlua_test"
import lists from "../lists"

local function numText(items: number[]): string
  local parts: string[] = {}
  for i: integer = 1, #items do parts[#parts + 1] = tostring(items[i]) end
  return table.concat(parts, ",")
end

local function strText(items: string[]): string
  return table.concat(items, "|")
end

local function boolText(items: boolean[]): string
  local parts: string[] = {}
  for i: integer = 1, #items do parts[#parts + 1] = tostring(items[i]) end
  return table.concat(parts, ",")
end

return {
  ["map, filter, reduce and forEach"] = function(): void
    local nums: integer[] = { 1, 2, 3, 4 }
    local mapped: string[] = lists.map<integer, string>(nums, function(n: integer): string
      return tostring(n * 2)
    end)
    T.eq(strText(mapped), "2|4|6|8", "map")
    local even: integer[] = lists.filter<integer>(nums, function(n: integer): boolean
      return n % 2 == 0
    end)
    T.eq(numText(even), "2,4", "filter")
    local total: integer = lists.reduce<integer, integer>(nums, function(acc: integer, n: integer): integer
      return acc + n
    end, 0)
    T.eq(total, 10, "reduce")
    local seen: integer[] = {}
    lists.forEach<integer>(nums, function(n: integer): void seen[#seen + 1] = n end)
    T.eq(numText(seen), "1,2,3,4", "forEach")
    T.eq(#lists.map<integer, integer>({}, function(n: integer): integer return n end), 0, "empty map")
  end,

  ["search and predicates"] = function(): void
    local nums: integer[] = { 3, 1, 4, 1, 5 }
    T.eq(lists.find<integer>(nums, function(n: integer): boolean return n > 3 end), 4, "find")
    T.eq(lists.find<integer>(nums, function(n: integer): boolean return n > 9 end), nil, "find missing")
    T.eq(lists.findIndex<integer>(nums, function(n: integer): boolean return n == 1 end), 1, "findIndex")
    T.eq(lists.findIndex<integer>(nums, function(n: integer): boolean return n == 9 end), -1, "findIndex missing")
    T.eq(lists.indexOf<integer>(nums, 4), 2, "indexOf")
    T.eq(lists.lastIndexOf<integer>(nums, 1), 3, "lastIndexOf")
    T.eq(lists.indexOf<integer>(nums, 9), -1, "indexOf missing")
    T.ok(lists.contains<integer>(nums, 5), "contains")
    T.ok(not lists.contains<integer>(nums, 9), "not contains")
    T.ok(lists.some<integer>(nums, function(n: integer): boolean return n > 4 end), "some")
    T.ok(lists.every<integer>(nums, function(n: integer): boolean return n > 0 end), "every")
    T.eq(lists.count<integer>(nums, function(n: integer): boolean return n == 1 end), 2, "count")
    T.ok(lists.isEmpty<integer>({}), "isEmpty")
    T.ok(not lists.isEmpty<integer>({ 1 }), "not isEmpty")
  end,

  ["unique, reverse, slice and take/drop"] = function(): void
    local nums: integer[] = { 1, 2, 1, 3, 2 }
    T.eq(numText(lists.unique<integer>(nums)), "1,2,3", "unique")
    T.eq(numText(lists.reverse<integer>(nums)), "2,3,1,2,1", "reverse")
    T.eq(numText(lists.slice<integer>(nums, 1, 4)), "2,1,3", "slice")
    T.eq(numText(lists.slice<integer>(nums, -2, 5)), "3,2", "negative slice")
    T.eq(numText(lists.slice<integer>(nums, 4, 2)), "", "reversed slice")
    T.eq(numText(lists.take<integer>(nums, 2)), "1,2", "take")
    T.eq(numText(lists.drop<integer>(nums, 3)), "3,2", "drop")
    T.eq(numText(lists.take<integer>(nums, 0)), "", "take zero")
    T.eq(numText(lists.drop<integer>(nums, 0)), "1,2,1,3,2", "drop zero")
    T.eq(numText(lists.copy<integer>(nums)), "1,2,1,3,2", "copy")
    local copy: integer[] = lists.copy<integer>(nums)
    copy[1] = 99
    T.eq(nums[1], 1, "copy is independent")
  end,

  ["concat, flatten, flatMap, chunk and zip"] = function(): void
    T.eq(numText(lists.concat<integer>({ 1, 2 }, { 3, 4 })), "1,2,3,4", "concat")
    T.eq(numText(lists.flatten<integer>({ { 1, 2 }, {}, { 3 } })), "1,2,3", "flatten")
    T.eq(numText(lists.flatMap<integer, integer>({ 1, 2, 3 }, function(n: integer): integer[]
      return { n, n * 10 }
    end)), "1,10,2,20,3,30", "flatMap")
    local chunks: integer[][] = lists.chunk<integer>({ 1, 2, 3, 4, 5 }, 2)
    T.eq(#chunks, 3, "chunk count")
    T.eq(numText(chunks[1]), "1,2", "chunk one")
    T.eq(numText(chunks[3]), "5", "chunk tail")
    T.raises(function(): void lists.chunk<integer>({ 1 }, 0) end)
    local zipped = lists.zip<string, integer>({ "a", "b" }, { 1, 2, 3 })
    T.eq(#zipped, 2, "zip length")
    T.eq(zipped[1].first, "a", "zip first")
    T.eq(zipped[2].second, 2, "zip second")
    T.eq(#lists.zip<string, integer>({}, { 1 }), 0, "empty zip")
  end,

  ["range and repeatValue"] = function(): void
    T.eq(numText(lists.range(0, 5, 1)), "0,1,2,3,4", "range")
    T.eq(numText(lists.range(5, 0, -2)), "5,3,1", "negative range")
    T.eq(numText(lists.range(0, 0, 1)), "", "empty range")
    T.raises(function(): void lists.range(0, 5, 0) end)
    T.eq(numText(lists.repeatValue<integer>(7, 3)), "7,7,7", "repeatValue")
    T.eq(numText(lists.repeatValue<integer>(7, 0)), "", "repeat zero")
  end,

  ["numeric aggregates"] = function(): void
    local nums: number[] = { 1, 2, 3, 4 }
    T.eq(lists.sum(nums), 10, "sum")
    T.eq(lists.sumBy<integer>({ 1, 2, 3 }, function(n: integer): number return n * 2 end), 12, "sumBy")
    T.eq(lists.minNumber(nums), 1, "min")
    T.eq(lists.maxNumber(nums), 4, "max")
    T.eq(lists.mean(nums), 2.5, "mean")
    T.raises(function(): void lists.minNumber({}) end)
    T.raises(function(): void lists.maxNumber({}) end)
    T.raises(function(): void lists.mean({}) end)
  end,

  ["sorting does not mutate"] = function(): void
    local nums: number[] = { 3, 1, 2 }
    T.eq(numText(lists.sortNumbers(nums, false)), "1,2,3", "sort asc")
    T.eq(numText(lists.sortNumbers(nums, true)), "3,2,1", "sort desc")
    T.eq(numText(nums), "3,1,2", "input untouched")
    local strs: string[] = { "b", "a", "c" }
    T.eq(strText(lists.sortStrings(strs, false)), "a|b|c", "string sort")
    T.eq(strText(lists.sortStrings(strs, true)), "c|b|a", "string sort desc")
    T.eq(numText(lists.sort<integer>({ 3, 1, 2 }, function(a: integer, b: integer): boolean
      return a > b
    end)), "3,2,1", "custom sort")
  end,

  ["groupBy, partition, first and last"] = function(): void
    local nums: integer[] = { 1, 2, 3, 4, 5, 6 }
    local groups: map<string, integer[]> = lists.groupBy<integer>(nums, function(n: integer): string
      if n % 2 == 0 then return "even" end
      return "odd"
    end)
    T.eq(numText(groups["even"]!), "2,4,6", "group even")
    T.eq(numText(groups["odd"]!), "1,3,5", "group odd")
    local split = lists.partition<integer>(nums, function(n: integer): boolean return n > 3 end)
    T.eq(numText(split.pass), "4,5,6", "partition pass")
    T.eq(numText(split.fail), "1,2,3", "partition fail")
    T.eq(lists.first<integer>(nums), 1, "first")
    T.eq(lists.last<integer>(nums), 6, "last")
    T.eq(lists.first<integer>({}), nil, "empty first")
    T.eq(lists.last<integer>({}), nil, "empty last")
  end,
}
