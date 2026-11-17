import T from "tlua_test"
import strings from "../strings"

local function joined(items: string[]): string
  return table.concat(items, "|")
end

return {
  ["trim, case and predicates"] = function(): void
    T.eq(strings.trim("  hello\t\r\n"), "hello", "trim")
    T.eq(strings.trimStart("  hello "), "hello ", "trimStart")
    T.eq(strings.trimEnd("  hello "), "  hello", "trimEnd")
    T.eq(strings.trimChars("xxhellox", "x"), "hello", "trimChars")
    T.eq(strings.trimStartChars("xxhellox", "x"), "hellox", "trimStartChars")
    T.eq(strings.trimEndChars("xxhellox", "x"), "xxhello", "trimEndChars")
    T.eq(strings.trimChars("abc", ""), "abc", "empty trim set")
    T.eq(strings.upper("aBc"), "ABC", "upper")
    T.eq(strings.lower("aBc"), "abc", "lower")
    T.ok(strings.startsWith("hello", "he"), "startsWith")
    T.ok(not strings.startsWith("he", "hello"), "startsWith too long")
    T.ok(strings.endsWith("hello", "lo"), "endsWith")
    T.ok(strings.contains("hello", "ell"), "contains")
    T.ok(strings.includes("hello", "xyz") == false, "includes false")
    T.eq(strings.find("hello", "l", 1), 3, "find")
    T.eq(strings.find("hello", "z", 1), nil, "find missing")
    T.eq(strings.find("hello", "l", 4), 4, "find from")
    T.eq(strings.indexOf("hello", "l"), 3, "indexOf")
    T.eq(strings.indexOf("hello", "z"), 0, "indexOf missing")
    T.eq(strings.indexOfFrom("hello", "l", 4), 4, "indexOfFrom")
    T.eq(strings.lastIndexOf("hello", "l"), 4, "lastIndexOf")
    T.eq(strings.lastIndexOf("hello", "z"), 0, "lastIndexOf missing")
  end,

  ["split, lines and whitespace"] = function(): void
    T.eq(joined(strings.split("a,b,c", ",")), "a|b|c", "split")
    T.eq(joined(strings.split("a,,c", ",")), "a||c", "empty item")
    T.eq(joined(strings.split(",a,", ",")), "|a|", "leading/trailing")
    T.eq(joined(strings.split("abc", "")), "a|b|c", "byte split")
    T.eq(joined(strings.split("", ",")), "", "empty split")
    T.eq(joined(strings.splitWhitespace("  a\tb\n c  ")), "a|b|c", "whitespace")
    T.eq(joined(strings.splitWhitespace("")), "", "empty whitespace")
    T.eq(joined(strings.lines("a\nb\r\nc")), "a|b|c", "lines")
    T.eq(joined(strings.lines("a\n")), "a", "trailing newline")
    T.eq(joined(strings.lines("a\n\n")), "a|", "blank final line")
    T.eq(joined(strings.lines("")), "", "empty lines")
    T.eq(strings.join({ "a", "b", "c" }, "-"), "a-b-c", "join")
    T.eq(strings.join({}, "-"), "", "empty join")
  end,

  ["replace, count, repeat and padding"] = function(): void
    T.eq(strings.replace("a.b.a", ".", "/"), "a/b/a", "replace")
    T.eq(strings.replace("aaa", "aa", "b"), "ba", "non-overlap")
    T.eq(strings.replace("abc", "", "x"), "abc", "empty old")
    T.eq(strings.replaceFirst("a.b.c", ".", "/"), "a/b.c", "replaceFirst")
    T.eq(strings.count("aaaa", "aa"), 2, "count non-overlap")
    T.eq(strings.count("abc", ""), 0, "empty needle")
    T.eq(strings.repeatString("ab", 3), "ababab", "repeat")
    T.eq(strings.repeatString("ab", 0), "", "repeat zero")
    T.eq(strings.repeatString("ab", -1), "", "repeat negative")
    T.eq(strings.padStart("7", 3, "0"), "007", "padStart")
    T.eq(strings.padEnd("7", 3, "0"), "700", "padEnd")
    T.eq(strings.padStart("hello", 3, "0"), "hello", "pad already wide")
    T.eq(strings.padStart("x", 4, "ab"), "abax", "multi-char pad")
    T.eq(strings.capitalize("hello"), "Hello", "capitalize")
    T.eq(strings.uncapitalize("Hello"), "hello", "uncapitalize")
    T.eq(strings.truncate("abcdef", 4, "..."), "a...", "truncate")
    T.eq(strings.truncate("abc", 4, "..."), "abc", "truncate short")
    T.eq(strings.truncate("abcdef", 2, "..."), "ab", "truncate tiny")
    T.ok(strings.isBlank(" \t\n"), "blank")
    T.ok(not strings.isBlank(" x "), "not blank")
  end,

  ["slice, chars and word cases"] = function(): void
    T.eq(strings.slice("abcdef", 1, 4), "bcd", "slice")
    T.eq(strings.slice("abcdef", -2, 6), "ef", "negative slice")
    T.eq(strings.slice("abcdef", 4, 2), "", "reversed slice")
    T.eq(strings.slice("abcdef", -100, 100), "abcdef", "clamped slice")
    T.eq(joined(strings.chars("abc")), "a|b|c", "chars")
    T.eq(joined(strings.words("helloWorld")), "hello|World", "camel words")
    T.eq(joined(strings.words("hello-world_test")), "hello|world|test", "word boundaries")
    T.eq(strings.snakeCase("HelloWorld value"), "hello_world_value", "snake")
    T.eq(strings.snakeCase("HTTPServer"), "http_server", "acronym words")
    T.eq(strings.kebabCase("HelloWorld value"), "hello-world-value", "kebab")
    T.eq(strings.camelCase("hello_world-value"), "helloWorldValue", "camel")
    T.eq(strings.pascalCase("hello_world-value"), "HelloWorldValue", "pascal")
  end,
}
