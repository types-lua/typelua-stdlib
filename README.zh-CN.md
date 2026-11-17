# typelua-stdlib

TypeLua 的轻量标准库：纯 TypeLua/Lua，无 C 模块依赖，支持 Lua 5.4 与
LuaJIT / Lua 5.1。

参考 Go、Python、JavaScript、Rust 基础标准库的常用能力，但保持 Lua 的
字节字符串和 1-based 数组语义。

## 模块

| 模块 | 能力 |
| --- | --- |
| `strings` | trim、大小写、查找、split/join、替换、padding、slice、命名风格转换 |
| `lists` | map/filter/reduce、查找、去重、slice、zip、flatten、chunk、range、排序、分组 |
| `maps` | keys/values/entries、get/set/remove、merge、pick/omit、mapValues、filter、equals |
| `mathx` | clamp、gcd/lcm、素数、阶乘/斐波那契、round、插值、median |
| `path` | POSIX normalize/join/dirname/basename/extname、parse、relative、isWithin |
| `encoding` | 严格 Base64/Base64URL/Base32、hex、percent/URL、form 编码 |
| `json` | 严格解析、确定性编码、pretty、null sentinel、深度/大小限制 |
| `time` | UTC 日历、ISO-8601 解析/格式化、日边界、duration |
| `fs` | 普通文件读写/追加/按行/大小/重命名/删除/复制，统一 result record |
| `random` | 确定性 xorshift32、整数/浮点/字节、choice/shuffle/sample |
| `hash` | SHA-1、SHA-256、HMAC-SHA256、常量时间比较 |
| `csv` | 严格 RFC 4180 解析/编码、引号/多行字段、资源限制 |
| `set` | 泛型集合、并/交/差/子集/相等 |
| `semver` | 严格 SemVer 2.0 解析、格式化、优先级比较 |
| `url` | 严格绝对 URL 解析/格式化、query 解析/构建 |
| `binary` | 边界检查的字节读写、显式大小端 |
| `unicode` | 严格 UTF-8 校验、解码/编码、码点计数 |
| `entropy` | POSIX `/dev/urandom` 安全随机字节、UUID v4 |
| `netip` | 严格 IPv4/IPv6 解析、规范化格式、CIDR 包含判断 |
| `crc32` | CRC-32 IEEE、CRC-32C、流式 extend、LevelDB mask |
| `collections` | 有界 FIFO 队列、动态栈、有界二叉优先队列 |
| `bitops` | 可移植 32 位位运算，供 hash/random 使用 |

不包含：YAML/XML、HTTP、加密/签名协议、目录遍历、时区数据库、国际化。
`hash` 是完整性/MAC 辅助模块，不替代经过审计的密码学库。

## 安装

```toml
# tlua.toml
[dependencies]
"github.com/types-lua/typelua-stdlib" = "^v0.2.7"
```

仓库已公开；如果通过私有镜像/fork 使用，再加 `url` 指向镜像。

```bash
tlua mod get
tlua mod vendor
```

```tl
import std from "github.com/types-lua/typelua-stdlib"
import json from "github.com/types-lua/typelua-stdlib/json"

print(std.strings.trim("  hello  "))
print(json.encode({ ok = true, values = { 1, 2, 3 } }))
```

TypeLua 的泛型目前需要显式类型参数：

```tl
local doubled = std.lists.map<integer, string>({ 1, 2 }, function(n: integer): string
  return tostring(n * 2)
end)
```

## 约定

- 数组是 1-based Lua sequence；`lists.slice` 和 `strings.slice` 是
  0-based、end-exclusive，支持负索引并自动 clamp。
- 纯函数遇到非法参数会 `error`；解析器和 I/O 返回 result record，
  使用前先检查 `ok`。
- map 遍历顺序不确定；需要确定性时显式排序。JSON 编码器会排序 key。
- `strings.chars` 按字节切分，不是 Unicode code point 迭代器。
- `random` 不提供隐藏全局状态，必须显式创建 `Random`。

## 测试

```bash
tlua check
tlua test
tlua test --lua lua5.4
tlua test --lua luajit --target 5.1
./scripts/check-package.sh
```

测试覆盖各模块边界、随机 Base64/hex 往返、随机 JSON 往返、path normalize
幂等性、UTC 日期大范围往返、shuffle 排列性质、错误分支和外部项目安装。

完整 API 说明见 [README.md](README.md)，安全边界和解析限制见 [SECURITY.md](SECURITY.md)。

## License

MIT。
