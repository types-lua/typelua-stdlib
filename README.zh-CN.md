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
| `encoding` | 严格 Base64/Base64URL、hex、percent/URL、form 编码 |
| `json` | 严格解析、确定性编码、pretty、null sentinel、深度/大小限制 |
| `time` | UTC 日历、ISO-8601 解析/格式化、日边界、duration |
| `fs` | 普通文件读写/追加/按行/大小/重命名/删除/复制，统一 result record |
| `random` | 确定性 xorshift32、整数/浮点/字节、choice/shuffle/sample |

不包含：YAML/CSV/XML、HTTP、加密哈希、目录遍历、时区数据库、国际化。
这些应该放到独立包或平台适配层。

## 安装

```toml
# tlua.toml
[dependencies]
"github.com/types-lua/typelua-stdlib" = "^v0.1.1"
```

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

完整 API 说明见 [README.md](README.md)。

## License

MIT。
