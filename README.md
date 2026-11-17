# typelua-stdlib

A small, typed, dependency-free standard-library package for
[TypeLua](https://github.com/types-lua/TypeLua), built for Lua 5.4 and
LuaJIT/Lua 5.1.

The design follows the useful core of Go's `strings`/`sort`, Python's
`str`/`json`/`pathlib`, JavaScript's `Array`/`Map`, Rust's `str`/`Option`-style
explicit results and Lua's own byte-string model. It is intentionally not a
replacement for Lua's base libraries: it adds predictable typed helpers,
strict parsers and explicit error records.

中文说明见 [`README.zh-CN.md`](README.zh-CN.md).

```tl
import std from "github.com/types-lua/typelua-stdlib"

print(std.strings.trim("  hello  "))
print(std.json.encode({ ok = true, values = { 1, 2, 3 } }))
print(std.path.join({ "/srv", "app", "config.json" }))
```

## Scope

| Module | What it covers |
| --- | --- |
| `strings` | trim, case, search, split/join, replace, padding, slicing, word-case conversion |
| `lists` | map/filter/reduce, search, unique, slice, zip, flatten, chunk, range, sort, groupBy |
| `maps` | keys/values/entries, get/set/remove, merge, pick/omit, mapValues, filter, equals |
| `mathx` | clamp, gcd/lcm, primes, factorial/fibonacci, rounding, interpolation, median |
| `path` | POSIX normalize/join/dirname/basename/extname, parse, relative, containment |
| `encoding` | strict Base64/Base64URL, hex, percent/URL and form encoding |
| `json` | strict parser, deterministic encoder, pretty printing, null sentinel, limits |
| `time` | UTC calendar math, ISO-8601 parse/format, day boundaries, durations |
| `fs` | regular-file read/write/append/lines/size/rename/remove/copy with result records |
| `random` | deterministic xorshift32 generator, ints/floats/bytes, choice/shuffle/sample |

What is deliberately **not** included: YAML/CSV/XML, HTTP, cryptographic hashes,
directory traversal/listing, timezone databases, localization, and
Unicode code-point iteration. Those belong in focused packages or platform
adapters.

## Install

```toml
# tlua.toml
[package]
name = "my-service"
version = "v0.1.0"

[dependencies]
# Private repository: give the Git URL explicitly so the package manager does
# not try an anonymous public lookup.
"github.com/types-lua/typelua-stdlib" = { version = "^v0.1.2", url = "git@github.com:types-lua/typelua-stdlib.git" }
```

```bash
tlua mod get
tlua mod vendor
```

If your Git client is configured for HTTPS instead of SSH, use
`https://github.com/types-lua/typelua-stdlib.git` as the `url` and make sure
your credential helper can access the private repository.

Then import the package root or an individual module:

```tl
import std from "github.com/types-lua/typelua-stdlib"
import strings from "github.com/types-lua/typelua-stdlib/strings"
import json from "github.com/types-lua/typelua-stdlib/json"
```

No ambient `.d.tl` types are required: each module's return type is inferred.
TypeLua currently requires explicit type arguments for generic helpers:

```tl
local doubled = std.lists.map<integer, string>({ 1, 2 }, function(n: integer): string
  return tostring(n * 2)
end)
```

Without the package manager, copy the module `.tl` files into
`tlua_modules/github.com/types-lua/typelua-stdlib/` (or use a Git submodule) and
keep the same import path. Avoid absolute filesystem imports.

## Conventions

- Arrays are 1-based Lua sequences. `lists.slice` and `strings.slice` are
  0-based and end-exclusive, matching modern standard libraries; both accept
  negative indexes and clamp to bounds.
- Pure helpers raise a Lua error for invalid programmer input (bad range,
  empty aggregate, zero step). Parsers and I/O return result records:
  `{ ok, data/error }`, `{ ok, value/error, position }`, etc. Check `ok` before
  using the payload.
- Map iteration order is unspecified, as in Lua. Functions that need
  determinism sort keys; the JSON encoder sorts object keys.
- Byte strings are used throughout. UTF-8 passes through; `strings.chars` is
  byte-oriented, not a Unicode code-point iterator.
- No hidden global state. `random` requires an explicit generator instance.

## Module guide

### strings

```tl
strings.trim(s) / trimStart / trimEnd
strings.trimChars(s, chars)
strings.lower(s) / upper(s)
strings.startsWith / endsWith / contains / includes
strings.indexOf / indexOfFrom / lastIndexOf       -- 1-based, 0 = missing
strings.split(s, sep) / splitWhitespace(s) / lines(s)
strings.join(parts, sep)
strings.replace(s, old, new) / replaceFirst
strings.count(s, needle)
strings.repeatString(s, n)
strings.padStart(s, width, pad) / padEnd
strings.capitalize / uncapitalize / truncate / isBlank
strings.chars(s) / slice(s, start, finish)
strings.words / snakeCase / kebabCase / camelCase / pascalCase
```

### lists

```tl
lists.map<T,U>(items, fn)
lists.filter<T>(items, predicate)
lists.reduce<T,U>(items, fn, initial)
lists.forEach<T>(items, fn)
lists.find<T> / findIndex<T> / indexOf<T> / lastIndexOf<T> / contains<T>
lists.some<T> / every<T> / count<T>
lists.unique<T> / copy<T> / reverse<T> / slice<T> / take<T> / drop<T>
lists.concat<T> / flatten<T> / flatMap<T,U> / chunk<T> / zip<A,B>
lists.range(start, finish, step)                   -- finish exclusive
lists.repeatValue<T>(value, count)
lists.sum / sumBy<T> / minNumber / maxNumber / mean
lists.sort<T>(items, less)                         -- returns a copy
lists.sortNumbers / sortStrings
lists.groupBy<T>(items, keyFn) / partition<T>
lists.first<T> / last<T> / isEmpty<T>
```

### maps

```tl
maps.keys<K,V> / values<K,V> / entries<K,V> / toArray<K,V>
maps.fromEntries<K,V>(entries)
maps.has<K,V> / get<K,V>(m, key, fallback) / getOrNil<K,V>
maps.set<K,V> / remove<K,V> / clear<K,V>
maps.clone<K,V> / merge<K,V> / mergeInto<K,V>
maps.pick<K,V> / omit<K,V>
maps.invert(m)                                     -- errors on duplicate values
maps.mapValues<K,V,U> / filter<K,V> / forEach<K,V>
maps.equals<K,V> / count<K,V> / isEmpty<K,V>
```

### mathx

```tl
mathx.clamp / clamp01 / sign / isFinite / isInteger
mathx.gcd / lcm / isPrime / factorial / fibonacci
mathx.round(value, digits) / approxEqual(a, b, epsilon)
mathx.lerp / inverseLerp / logBase / hypot
mathx.divMod(a, b) / safeDivide(a, b, fallback) / percent(part, total)
mathx.sum / mean / median / radians / degrees
```

### path

```tl
path.isAbsolute(p)
path.normalize(p) / join(parts)
path.dirname(p) / basename(p) / extname(p) / stem(p)
path.parse(p)                                      -- {root, dir, base, ext, name}
path.segments(p) / relative(from, to)
path.isWithin(base, target)                        -- segment-aware containment
path.withExtension(p, ext) / removeExtension(p) / toPosix(p)
```

`isWithin` is useful before mapping a static-file or archive path: it compares
normalized path segments rather than string prefixes, rejects `..` escapes and
does not allow `"/srv/app"` to contain `"/srv/application"`.

### encoding

```tl
encoding.base64Encode(data) / base64Decode(text)   -- strict DecodeResult
encoding.base64UrlEncode(data) / base64UrlDecode(text)
encoding.hexEncode(data) / hexEncodeUpper(data) / hexDecode(text)
encoding.percentEncode(text) / percentDecode(text) -- URL component encoding
encoding.formEncode(text) / formDecode(text)       -- application/x-www-form-urlencoded
```

`DecodeResult` is `{ ok: boolean, data: string, error: string }`. Malformed
padding, alphabet, escapes and trailing bits are rejected, not silently
skipped.

### json

```tl
json.decode(text)                                  -- JsonDecodeResult
json.decodeWith(text, { maxDepth = 512, maxBytes = 8388608 })
json.encode(value)                                 -- throws on unsupported values
json.encodeResult(value)                           -- JsonEncodeResult
json.encodePretty(value, indent) / encodePrettyResult
json.null / json.isNull(value) / json.JsonNull
```

- `JsonDecodeResult` is `{ ok, value, error, position }`.
- `null` is the sentinel `json.null`, not Lua `nil`, so arrays/objects can carry
  null without holes. Encoding `nil` also emits `null`.
- Objects are tables with string keys. Arrays are tables with exactly the
  contiguous integer keys `1..n`. Empty tables encode as `{}` by design; an
  explicit empty array is application-specific.
- Encoding rejects cycles, sparse arrays, mixed object/array keys, non-string
  object keys and NaN/Infinity. Object keys are sorted for deterministic output.
- Decoding rejects invalid number forms, control characters, bad escapes,
  lone surrogates, trailing data and exceeds of the depth/byte limits.

### time

```tl
time.now()
time.isLeapYear(year) / daysInMonth(year, month)
time.dateParts(timestamp)                          -- UTC fields
time.fromParts({year, month, day, hour, minute, second})
time.parseIso8601(text) / iso8601(timestamp)
time.formatUtc(timestamp, pattern)
time.addSeconds / addDays
time.startOfDayUtc / endOfDayUtc
time.weekday(timestamp)                            -- 0 Sunday .. 6 Saturday
time.isoWeekday(timestamp)                         -- 1 Monday .. 7 Sunday
time.duration(seconds)
```

All calendar math is UTC and independent of the process timezone/locale.
`parseIso8601` accepts a date, `YYYY-MM-DDTHH:MM:SS`, optional fractional
seconds, and `Z`/`±HH:MM` offsets.

### fs

```tl
fs.readFile(path)                                  -- {ok, data, error}
fs.writeFile(path, data) / appendFile(path, data)
fs.readLines(path) / writeLines(path, lines)
fs.isFile(path) / exists(path) / size(path)
fs.remove(path) / rename(from, to) / copy(from, to)
fs.readFileOr(path, fallback)
```

Only regular files are supported. Directories deliberately return false for
`isFile`/`exists`; use a platform adapter when directory traversal is needed.
All fallible operations return records instead of throwing.

### random

```tl
local rng = random.Random.new(seed)
rng:nextUint() / nextFloat() / nextInt(min, max) / bool(probability)
rng:nextBytes(count)
random.choice<T>(rng, items)
random.shuffle<T>(rng, items)                      -- returns a copy
random.sample<T>(rng, items, count)
```

xorshift32 is deterministic across Lua 5.4 and LuaJIT and is **not** suitable
for cryptography. `nextInt` rejects ranges wider than 32 bits and uses
rejection sampling to avoid modulo bias.

## Testing

```bash
tlua check
tlua test
tlua test --lua lua5.4
tlua test --lua luajit --target 5.1
./scripts/check-package.sh
```

The suite includes per-module edge cases, randomized Base64/hex round-trips,
randomized JSON round-trips, path-normalization idempotence, time civil-date
round-trips over a wide timestamp range, shuffle permutation checks, error
cases and an external-project install smoke test.

## License

MIT. See [`LICENSE`](LICENSE).
