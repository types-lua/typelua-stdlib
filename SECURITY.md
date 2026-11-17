# Security notes

typelua-stdlib is a utility library, not a sandbox, TLS stack, password
hashing library or authorization framework. Treat every byte string from the
network, filesystem, command line or another service as untrusted input.

## Parsing limits

All structured parsers have explicit defaults and optional overrides:

| Parser | Defaults |
| --- | --- |
| JSON decode | 8 MiB input, 512 nested arrays/objects |
| JSON encode | 512 nested arrays/objects, rejects cycles/sparse/mixed tables |
| CSV | 16 MiB input, 1,000,000 rows, 10,000 fields/row, 1 MiB/field |
| URL | 8 KiB URL, raw control/space rejected, port 0..65535 |
| SemVer | 256 bytes, bounded numeric components (<= 2^53-1) |
| Binary reader | every read is bounds-checked before consuming bytes |
| Entropy | max 1 MiB per request, explicit error if `/dev/urandom` is unavailable |

Limits are checked while parsing or before a read; they are not an invitation
to raise them without considering memory and CPU denial-of-service risk.

## Paths and files

`path.isWithin` is a **lexical** containment check over normalized POSIX
segments. It rejects `..` escapes and prefix confusion (`/srv/app` vs
`/srv/application`), but it does not resolve symlinks. If paths cross a
symlink boundary, resolve the real filesystem path with a platform adapter
before serving files.

`fs` only handles regular files. It deliberately has no directory creation or
listing API, and never invokes a shell. File paths are passed directly to Lua
I/O functions; do not build shell commands from user paths.

## CSV and spreadsheets

The CSV encoder implements RFC 4180 quoting. It does not neutralize spreadsheet
formula injection (`=`, `+`, `-`, `@` at the start of a cell). If exported CSV
is opened in a spreadsheet, apply an application-specific escaping policy.

## Hash and entropy

- `hash` provides SHA-1, SHA-256 and HMAC-SHA256 for integrity/MAC use.
  `constantTimeEqual` avoids early exit on content, but length is observable.
- SHA-1 is for protocol compatibility only; do not use it for new security
  designs.
- `entropy` reads `/dev/urandom` on POSIX systems and has no insecure fallback.
  It is not available on platforms without that device; use an OS adapter there.
- Deterministic `random` is not cryptographic and must never generate keys,
  tokens, passwords or session identifiers.

## URL and JSON ambiguity

- `url` does not perform DNS resolution, IDNA conversion, path percent-decoding
  or redirect policy. Apply those at the application/proxy boundary.
- Query duplicate keys keep the last value; document that behavior if it matters
  to authorization decisions.
- JSON duplicate object keys keep the last value. The encoder emits sorted keys
  for determinism. Empty Lua tables encode as `{}`; model empty arrays explicitly.
- JSON `null` is the `json.null` sentinel, not `nil`, so arrays preserve holes.

## What is intentionally absent

TLS termination, certificate validation, authentication, password hashing,
encryption, signing schemes, YAML/XML, HTTP, directory traversal/listings, time
zone databases, localization and Unicode normalization are outside this package.
Use focused, audited components for those jobs.
