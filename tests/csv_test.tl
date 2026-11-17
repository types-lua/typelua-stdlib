import T from "tlua_test"
import csv from "../csv"

local function dump(rows: string[][]): string
  local records: string[] = {}
  for i: integer = 1, #rows do
    records[#records + 1] = table.concat(rows[i], "|")
  end
  return table.concat(records, ";;")
end

return {
  ["plain rows and newline styles"] = function(): void
    local crlf = csv.parse("a,b\r\nc,d")
    T.ok(crlf.ok, "crlf ok")
    T.eq(dump(crlf.rows), "a|b;;c|d", "crlf rows")
    local lf = csv.parse("a,b\nc,d\n")
    T.ok(lf.ok, "lf ok")
    T.eq(dump(lf.rows), "a|b;;c|d", "lf rows")
    local empty = csv.parse("")
    T.ok(empty.ok, "empty ok")
    T.eq(#empty.rows, 0, "empty rows")
    local blank = csv.parse("\n")
    T.eq(dump(blank.rows), "", "blank line is one empty field")
    T.eq(#blank.rows[1], 1, "blank line field count")
    local trailing = csv.parse("a,\n")
    T.eq(dump(trailing.rows), "a|", "trailing empty field")
    local single = csv.parse("a")
    T.eq(dump(single.rows), "a", "single field")
  end,

  ["quoted fields, quotes and embedded newlines"] = function(): void
    local result = csv.parse("\"a,b\",\"line1\nline2\",\"quote\"\"inside\"")
    T.ok(result.ok, "quoted ok")
    T.eq(#result.rows, 1, "one row")
    T.eq(result.rows[1][1], "a,b", "comma")
    T.eq(result.rows[1][2], "line1\nline2", "newline")
    T.eq(result.rows[1][3], "quote\"inside", "escaped quote")
    local empty = csv.parse("\"\",\"\"")
    T.ok(empty.ok, "empty quoted")
    T.eq(#empty.rows[1], 2, "empty quoted count")
    T.eq(empty.rows[1][1], "", "empty quoted value")
    local custom = csv.parseWith("a;b\nc;d", { delimiter = ";" })
    T.eq(dump(custom.rows), "a|b;;c|d", "custom delimiter")
  end,

  ["encode and round-trip"] = function(): void
    local rows: string[][] = {
      { "a", "b" },
      { "with,comma", "with\"quote" },
      { "line1\nline2", "" },
    }
    local encoded: string = csv.encode(rows)
    T.eq(
      encoded,
      "a,b\r\n\"with,comma\",\"with\"\"quote\"\r\n\"line1\nline2\",",
      "encoded"
    )
    local decoded = csv.parse(encoded)
    T.ok(decoded.ok, "round-trip parse")
    T.eq(#decoded.rows, 3, "round-trip rows")
    T.eq(decoded.rows[2][1], "with,comma", "comma field")
    T.eq(decoded.rows[2][2], "with\"quote", "quote field")
    T.eq(decoded.rows[3][1], "line1\nline2", "newline field")
    T.eq(decoded.rows[3][2], "", "empty field")
    local custom: string = csv.encodeWith({ { "a", "b" }, { "c", "d" } }, { delimiter = ";" })
    T.eq(custom, "a;b\r\nc;d", "custom encode")
    T.eq(csv.encode({}), "", "empty encode")
  end,

  ["malformed input"] = function(): void
    T.ok(not csv.parse("\"unterminated").ok, "unterminated quote")
    T.ok(not csv.parse("a\"b").ok, "quote in unquoted")
    T.ok(not csv.parse("\"a\"x").ok, "character after quote")
    T.ok(not csv.parse("a\rb").ok, "bare CR")
    T.ok(not csv.parse("a\r").ok, "trailing CR")
  end,

  ["limits and validation"] = function(): void
    T.raises(function(): void csv.parseWith("a", { delimiter = "::" }) end)
    T.raises(function(): void csv.parseWith("a", { delimiter = "\"" }) end)
    T.raises(function(): void csv.parseWith("a", { delimiter = "\n" }) end)
    T.ok(not csv.parseWith("abcdef", { maxBytes = 3 }).ok, "maxBytes")
    T.ok(not csv.parseWith("a,b", { maxFields = 1 }).ok, "maxFields")
    T.ok(not csv.parseWith("a\nb", { maxRows = 1 }).ok, "maxRows")
    T.ok(not csv.parseWith("abcdef", { maxFieldBytes = 3 }).ok, "maxFieldBytes")
    T.raises(function(): void csv.parseWith("a", { maxFields = 0 }) end)
  end,
}
