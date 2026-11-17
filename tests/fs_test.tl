import T from "tlua_test"
import fs from "../fs"

return {
  ["read, write, append and size"] = function(): void
    local file: string = os.tmpname()
    local missing = fs.readFile(file .. ".missing")
    T.ok(not missing.ok, "missing read")
    T.ok(#missing.error > 0, "missing error")
    T.ok(fs.writeFile(file, "hello"), "write")
    T.ok(fs.isFile(file), "isFile")
    T.ok(fs.exists(file), "exists")
    T.eq(fs.readFile(file).data, "hello", "read")
    local size = fs.size(file)
    T.ok(size.ok, "size ok")
    T.eq(size.size, 5, "size")
    local appended = fs.appendFile(file, " world")
    T.ok(appended.ok, "append")
    T.eq(fs.readFile(file).data, "hello world", "append read")
    T.ok(fs.writeFile(file, "reset").ok, "overwrite")
    T.eq(fs.readFile(file).data, "reset", "overwrite read")
    T.eq(fs.readFileOr(file, "fallback"), "reset", "readFileOr")
    T.eq(fs.readFileOr(file .. ".missing", "fallback"), "fallback", "readFileOr missing")
    T.ok(fs.remove(file).ok, "remove")
    T.ok(not fs.isFile(file), "removed isFile")
    T.ok(not fs.exists(file), "removed exists")
    T.ok(not fs.remove(file).ok, "remove missing")
  end,

  ["lines, copy and rename"] = function(): void
    local first: string = os.tmpname()
    local second: string = os.tmpname()
    local third: string = os.tmpname()
    T.ok(fs.writeLines(first, { "a", "b", "c" }).ok, "writeLines")
    local lines = fs.readLines(first)
    T.ok(lines.ok, "readLines")
    T.eq(#lines.lines, 3, "line count")
    T.eq(lines.lines[1], "a", "line one")
    T.eq(lines.lines[3], "c", "line three")
    T.ok(fs.writeFile(first, "x\r\ny\r\n").ok, "write CRLF")
    local crlf = fs.readLines(first)
    T.eq(crlf.lines[1], "x", "CRLF line one")
    T.eq(crlf.lines[2], "y", "CRLF line two")
    T.ok(fs.writeLines(first, {}).ok, "empty lines")
    T.eq(fs.size(first).size, 0, "empty file")
    T.ok(fs.copy(first, second).ok, "copy")
    T.eq(fs.readFile(second).data, "", "copy empty")
    T.ok(fs.writeFile(first, "copy me").ok, "copy source")
    T.ok(fs.copy(first, second).ok, "copy content")
    T.eq(fs.readFile(second).data, "copy me", "copy read")
    T.ok(fs.rename(second, third).ok, "rename")
    T.ok(not fs.exists(second), "rename source gone")
    T.eq(fs.readFile(third).data, "copy me", "rename read")
    T.ok(not fs.copy(first, "/definitely/missing/dir/x").ok, "copy failure")
    fs.remove(first)
    fs.remove(third)
  end,

  ["directory handling is explicit"] = function(): void
    T.ok(not fs.isFile("/tmp"), "directory is not a file")
    T.ok(not fs.exists("/tmp"), "directory not exists for this API")
    local size = fs.size("/tmp")
    T.ok(not size.ok, "directory size fails")
    T.ok(not fs.readFile("/tmp").ok, "directory read fails")
  end,
}
