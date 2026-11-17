# typelua-stdlib

A typed, dependency-free standard-library package for
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
| `hash` | SHA-1, SHA-256, HMAC-SHA256, constant-time MAC comparison |
| `csv` | strict RFC 4180 parser/encoder with limits and quoted multiline fields |
| `set` | generic set with union/intersection/difference/subset/equality |
| `semver` | strict SemVer 2.0 parsing, formatting and precedence |
| `url` | strict absolute URL parser, formatter, query parse/build |
| `binary` | bounds-checked byte reader/writer with explicit endianness |
| `unicode` | strict UTF-8 validation, decode/encode, code-point count |
| `entropy` | OS entropy bytes and UUID v4 generation (POSIX `/dev/urandom`) |
| `netip` | strict IPv4/IPv6 parsing, canonical formatting, CIDR containment |
| `crc32` | CRC-32 IEEE and CRC-32C checksums, streaming extend, LevelDB mask |
| `collections` | bounded FIFO queue, dynamic stack, bounded binary priority queue |
| `bitops` | portable 32-bit bit operations used by hash/random |

What is deliberately **not** included: YAML/XML, HTTP, encryption/signature
schemes, directory traversal/listing, timezone databases, localization, and
Unicode code-point iteration. Those belong in focused packages or platform
adapters. `hash` is an integrity/MAC helper, not a replacement for a vetted
cryptographic library when side-channel or key-management guarantees matter.

## Install

```toml
# tlua.toml
[package]
name = "my-service"
version = "v0.1.0"

[dependencies]
"github.com/types-lua/typelua-stdlib" = "^v0.2.7"
```

```bash
tlua mod get
tlua mod vendor
```

The repository is public. If you consume it through a private mirror/fork, use
the explicit form and point `url` at that mirror:

```toml
"github.com/types-lua/typelua-stdlib" = { version = "^v0.2.7", url = "git@github.com:your-org/typelua-stdlib.git" }
```

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
strings.find(s, needle, start)                    -- 1-based, nil = missing
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
encoding.base32Encode(data) / base32Decode(text)
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

### hash

```tl
hash.sha1(data) / sha1Hex(data)
hash.sha256(data) / sha256Hex(data)
hash.hmacSha256(key, data) / hmacSha256Hex(key, data)
hash.constantTimeEqual(a, b)
```

Pure byte-string implementations. Use `constantTimeEqual` for MAC/tag
comparison; it avoids early exit on content differences. SHA-1 is included for
protocol compatibility, not for new security designs.

### csv

```tl
csv.parse(text)                                    -- CsvResult
csv.parseWith(text, { delimiter, maxBytes, maxRows, maxFields, maxFieldBytes })
csv.encode(rows) / encodeWith(rows, { delimiter })
```

Strict RFC 4180-style behavior: quoted commas/newlines, doubled quotes,
CRLF/LF records, and errors for malformed quotes, bare CR, truncated fields and
limit violations. The encoder uses CRLF between records and quotes when needed;
empty fields are quoted as `""` so a single-empty-field row is distinguishable
from no row.

### set

Set membership uses Lua equality; iteration order is unspecified.

```tl
Set.new<string>()                                  -- explicit type argument
s:add(value) / remove(value) / has(value) / contains(value)
s:size() / isEmpty() / values() / toArray() / clear() / forEach(fn)
s:union(other) / intersection(other) / difference(other)
s:isSubsetOf(other) / equals(other) / clone()
set.from<T>(values)
```

Bulk operations return new sets and do not mutate inputs.

### semver

```tl
semver.parse(text)                                 -- SemverResult
semver.format(version)
semver.compare(a, b) / compareText(aText, bText)
semver.isValid(text)
```

Strict SemVer 2.0: numeric components cannot have leading zeroes, prerelease
numeric identifiers are validated, and build metadata is ignored for
precedence.

### url

```tl
url.parse(text) / parseWith(text, { maxLength })
url.format(parts)
url.parseQuery(text)                               -- QueryResult
url.buildQuery(values)                             -- sorted keys
```

Strict absolute URLs, bracketed IPv6, ports, userinfo, query/fragment
preservation, raw control/space rejection and length limits. Query helpers use
`application/x-www-form-urlencoded` decoding; duplicate keys keep the last
value. DNS, IDNA and path percent-decoding are not performed.

### binary

```tl
local r = binary.ByteReader.new(data)
r:u8() / i8() / u16le() / u16be() / u32le() / u32be() / i32le() / i32be()
r:bytes(n) / peek(n) / skip(n) / position() / remaining() / eof()

local w = binary.ByteWriter.new()
w:u8(v) / i8(v) / u16le(v) / u16be(v) / u32le(v) / u32be(v) / i32le(v) / i32be(v)
w:bytes(data) / append(data) / length() / clear() / toString()
```

Readers raise on truncation; writers validate numeric ranges. Multi-byte
methods state their byte order explicitly.

### unicode

```tl
unicode.valid(text)                                -- strict UTF-8 bool
unicode.decode(text)                               -- {ok, codepoints, error}
unicode.encode(codepoints)                         -- {ok, text, error}
unicode.char(codepoint)                            -- throws on invalid code point
unicode.length(text)                               -- {ok, length, error}
unicode.codepointAt(text, bytePosition)            -- {ok, codepoint, error}
```

Rejects overlong forms, surrogate code points, truncated sequences and values
above U+10FFFF. Named `unicode` rather than `utf8` so it does not collide with
Lua 5.4's built-in `utf8` module.

### entropy

```tl
entropy.available()                                -- read one byte from /dev/urandom
entropy.bytes(count)                               -- {ok, data, error}, max 1 MiB
entropy.uuidV4()                                   -- {ok, value, error}
```

Uses the operating system's `/dev/urandom` directly, never the deterministic
`random` generator or the clock. On platforms without that device the result is
an explicit error; there is no insecure fallback. UUID v4 sets the standard
version/variant bits from 122 random bits.

### netip

```tl
netip.parse(text) / parseV4 / parseV6            -- {ok, ip, error}
netip.format(ip) / formatCidr(cidr)
netip.parseCidr(text)                            -- {ok, cidr, error}
netip.network(cidr) / contains(cidr, ip) / containsText(cidr, text)
netip.isV4 / isV6 / equal
netip.isUnspecified / isLoopback / isPrivate / isLinkLocal / isMulticast
netip.isV4Mapped / mappedV4
```

IPv4-mapped IPv6 addresses (`::ffff:a.b.c.d`) are recognized and classified as
their IPv4 equivalent, so a mapped private/loopback address cannot bypass a
policy check.

Strict decimal IPv4 (no leading zeroes), strict IPv6 with `::` compression
including embedded IPv4, canonical RFC 5952 formatting and prefix-bit-aware
CIDR containment. No DNS, zone identifiers or IPv4 shorthand. Useful for
allowlists and SSRF-style checks.

### crc32

```tl
crc32.crc32(data) / crc32Hex(data)                -- IEEE 802.3
crc32.crc32c(data) / crc32cHex(data)              -- Castagnoli
crc32.crc32Extend(crc, data) / crc32cExtend(crc, data)
crc32.crc32cMask(crc) / crc32cUnmask(masked)
```

Portable reflected CRC implementations. `*Extend` chains finalized CRCs and
matches LevelDB's record format; CRC is an integrity check, not a MAC.

### collections

```tl
local q = collections.Queue.new<string>(8)          -- capacity required
q:enqueue(value) / dequeue() / peek() / size() / isFull() / toArray()

local s = collections.Stack.new<integer>()
s:push(value) / pop() / peek() / size() / toArray()

local pq = collections.PriorityQueue.new<integer>(8, function(a, b) return a < b end)
pq:push(value) / pop() / peek() / size() / isFull()
```

Queue and priority queue are bounded; `enqueue`/`push` return false when full.
PriorityQueue is a binary min-heap (swap the comparator for max-heap behavior);
`toArray` returns heap order, not sorted order.

### bitops

Low-level portable 32-bit operations: `band`, `bor`, `bxor`, `bnot`, `lshift`,
`rshift`, `rotl`, `rotr`, `add`. Useful when implementing binary formats or
hashes; application code normally does not need it.

## Testing

```bash
tlua check
tlua test
tlua test --lua lua5.4
tlua test --lua luajit --target 5.1
./scripts/check-package.sh
```

The suite includes per-module edge cases, SHA/HMAC standard vectors,
randomized Base64/hex/CSV/binary round-trips, randomized JSON round-trips,
strict UTF-8 rejection cases, path-normalization idempotence, time civil-date
round-trips over a wide timestamp range, shuffle permutation checks, error
cases, OS-entropy/UUID checks and an external-project install smoke test.

## Security

See [`SECURITY.md`](SECURITY.md) for parser limits, path/symlink caveats,
hash/entropy guidance and CSV formula-injection notes.

## License

MIT. See [`LICENSE`](LICENSE).
