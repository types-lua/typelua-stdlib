--- Small, explicit regular-file helpers.
---
--- Lua's standard library has no portable directory API, so this module
--- intentionally focuses on regular file contents, sizes, rename/remove and
--- copy. `exists`/`isFile` return false for directories; directory operations
--- belong in a platform adapter such as LuaFileSystem or an application port.
---
--- Every fallible operation returns a record instead of throwing:
--- `ok`, optional payload, and `error`.

import strings from "./strings"

type FsResult = {
  ok: boolean,
  error: string,
}

type FsReadResult = {
  ok: boolean,
  data: string,
  error: string,
}

type FsLinesResult = {
  ok: boolean,
  lines: string[],
  error: string,
}

type FsSizeResult = {
  ok: boolean,
  size: integer,
  error: string,
}

local function success(): FsResult
  return { ok = true, error = "" }
end

local function failure(message: string): FsResult
  return { ok = false, error = message }
end

local function readFailure(message: string): FsReadResult
  return { ok = false, data = "", error = message }
end

local function readFile(path: string): FsReadResult
  local handle: any = nil
  local openErr: any = nil
  handle, openErr = io.open(path, "rb")
  if handle == nil then
    return readFailure(tostring(openErr))
  end
  local data: any = nil
  local readErr: any = nil
  data, readErr = handle:read("*a")
  if data == nil then
    handle:close()
    return readFailure(tostring(readErr))
  end
  handle:close()
  return { ok = true, data = data as string, error = "" }
end

local function writeFile(path: string, data: string): FsResult
  local handle: any = nil
  local openErr: any = nil
  handle, openErr = io.open(path, "wb")
  if handle == nil then
    return failure(tostring(openErr))
  end
  local writeOk: any = nil
  local writeErr: any = nil
  writeOk, writeErr = handle:write(data)
  if writeOk == nil then
    handle:close()
    return failure(tostring(writeErr))
  end
  local closeOk: any = nil
  local closeErr: any = nil
  closeOk, closeErr = handle:close()
  if closeOk == nil then
    return failure(tostring(closeErr))
  end
  return success()
end

local function appendFile(path: string, data: string): FsResult
  local handle: any = nil
  local openErr: any = nil
  handle, openErr = io.open(path, "ab")
  if handle == nil then
    return failure(tostring(openErr))
  end
  local writeOk: any = nil
  local writeErr: any = nil
  writeOk, writeErr = handle:write(data)
  if writeOk == nil then
    handle:close()
    return failure(tostring(writeErr))
  end
  local closeOk: any = nil
  local closeErr: any = nil
  closeOk, closeErr = handle:close()
  if closeOk == nil then
    return failure(tostring(closeErr))
  end
  return success()
end

local function isFile(path: string): boolean
  local handle: any = nil
  local openErr: any = nil
  handle, openErr = io.open(path, "rb")
  if handle == nil then return false end
  local data: any = nil
  local readErr: any = nil
  data, readErr = handle:read(1)
  handle:close()
  -- An empty regular file also returns nil from read(1), but with no error.
  return not (data == nil and readErr ~= nil)
end

local function exists(path: string): boolean
  return isFile(path)
end

local function size(path: string): FsSizeResult
  local handle: any = nil
  local openErr: any = nil
  handle, openErr = io.open(path, "rb")
  if handle == nil then
    return { ok = false, size = 0, error = tostring(openErr) }
  end
  local position: any = nil
  local seekErr: any = nil
  position, seekErr = handle:seek("end")
  if position == nil then
    handle:close()
    return { ok = false, size = 0, error = tostring(seekErr) }
  end
  handle:close()
  return { ok = true, size = position as integer, error = "" }
end

local function readLines(path: string): FsLinesResult
  local result: FsReadResult = readFile(path)
  if not result.ok then
    return { ok = false, lines = {}, error = result.error }
  end
  return { ok = true, lines = strings.lines(result.data), error = "" }
end

local function writeLines(path: string, lines: string[]): FsResult
  local data: string = table.concat(lines, "\n")
  if #lines > 0 then data = data .. "\n" end
  return writeFile(path, data)
end

local function remove(path: string): FsResult
  local ok: any = nil
  local message: any = nil
  ok, message = os.remove(path)
  if ok == nil then return failure(tostring(message)) end
  return success()
end

local function rename(fromPath: string, toPath: string): FsResult
  local ok: any = nil
  local message: any = nil
  ok, message = os.rename(fromPath, toPath)
  if ok == nil then return failure(tostring(message)) end
  return success()
end

local function copy(fromPath: string, toPath: string): FsResult
  local source: FsReadResult = readFile(fromPath)
  if not source.ok then return failure(source.error) end
  return writeFile(toPath, source.data)
end

local function readFileOr(path: string, fallback: string): string
  local result: FsReadResult = readFile(path)
  if not result.ok then return fallback end
  return result.data
end

return {
  readFile = readFile,
  writeFile = writeFile,
  appendFile = appendFile,
  readLines = readLines,
  writeLines = writeLines,
  isFile = isFile,
  exists = exists,
  size = size,
  remove = remove,
  rename = rename,
  copy = copy,
  readFileOr = readFileOr,
}
