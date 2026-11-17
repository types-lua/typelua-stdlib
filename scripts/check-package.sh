#!/usr/bin/env bash
# Consume typelua-stdlib exactly like an external project.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TLUA="${TLUA:-tlua}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

APP="$TMP/app"
mkdir -p "$APP"
cat > "$APP/tlua.toml" <<EOF
[package]
name = "stdlib-smoke"
version = "v0.1.0"

[dependencies]
"github.com/types-lua/typelua-stdlib" = { path = "$ROOT" }
EOF

cat > "$APP/tlua.json" <<'EOF'
{
  "compilerOptions": {
    "target": "5.4",
    "strict": true,
    "strictNilChecks": true,
    "noImplicitAny": true,
    "rootDir": ".",
    "outDir": "dist"
  },
  "include": ["**/*.tl"],
  "exclude": ["dist"]
}
EOF

cat > "$APP/main.tl" <<'TL'
import std from "github.com/types-lua/typelua-stdlib"
import strings from "github.com/types-lua/typelua-stdlib/strings"
import json from "github.com/types-lua/typelua-stdlib/json"

local doubled = std.lists.map<integer, string>({ 1, 2, 3 }, function(n: integer): string
  return tostring(n * 2)
end)
print("trim=" .. strings.trim("  ok  "))
print("joined=" .. table.concat(doubled, ","))
print("json=" .. json.encode({ ok = true, n = 2 }))
print("path=" .. std.path.join({ "a", "..", "b" }))
print("b64=" .. std.encoding.base64Encode("hi"))
print("epoch=" .. std.time.iso8601(0))
TL

(cd "$APP" && "$TLUA" mod get >/dev/null && "$TLUA" mod vendor >/dev/null)
# A local path dependency may include an ignored dist/ tree; a Git checkout
# would not. Remove it so this mirrors remote consumption.
rm -rf "$APP/tlua_modules/github.com/types-lua/typelua-stdlib/dist"

(cd "$APP" && "$TLUA" check)
(cd "$APP" && "$TLUA" build >/dev/null)
(cd "$APP/dist" && lua5.4 main.lua)

(cd "$APP" && "$TLUA" build --target 5.1 >/dev/null)
(cd "$APP/dist" && luajit main.lua)

echo "stdlib package smoke test passed"
