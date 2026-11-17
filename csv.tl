--- Strict RFC 4180-style CSV parsing and encoding.
---
--- The parser is incremental in spirit but operates on a complete byte string:
--- quoted fields may contain delimiters, CR/LF and doubled quotes. Malformed
--- quotes, bare CR outside quotes and resource-limit violations are errors, not
--- silently repaired input. This makes it suitable for configuration/import
--- paths where ambiguity is a security problem.

type CsvOptions = {
  delimiter?: string,
  maxBytes?: integer,
  maxRows?: integer,
  maxFields?: integer,
  maxFieldBytes?: integer,
}

type CsvResult = {
  ok: boolean,
  rows: string[][],
  error: string,
  row: integer,
  column: integer,
}

type CsvEncodeOptions = {
  delimiter?: string,
}

local DEFAULT_MAX_BYTES: integer = 16 * 1024 * 1024
local DEFAULT_MAX_ROWS: integer = 1000000
local DEFAULT_MAX_FIELDS: integer = 10000
local DEFAULT_MAX_FIELD_BYTES: integer = 1024 * 1024

local S_START: integer = 1
local S_UNQUOTED: integer = 2
local S_QUOTED: integer = 3
local S_AFTER_QUOTE: integer = 4

local function validateDelimiter(delimiter: string): void
  if #delimiter ~= 1 then error("CSV delimiter must be exactly one byte") end
  if delimiter == "\"" or delimiter == "\r" or delimiter == "\n" then
    error("CSV delimiter must not be a quote or newline")
  end
end

local function parseWith(text: string, options: CsvOptions): CsvResult
  local delimiter: string = ","
  local maxBytes: integer = DEFAULT_MAX_BYTES
  local maxRows: integer = DEFAULT_MAX_ROWS
  local maxFields: integer = DEFAULT_MAX_FIELDS
  local maxFieldBytes: integer = DEFAULT_MAX_FIELD_BYTES
  local delimiterOption: string | nil = options.delimiter
  if delimiterOption ~= nil then delimiter = delimiterOption! end
  local bytesOption: integer | nil = options.maxBytes
  if bytesOption ~= nil then maxBytes = bytesOption! end
  local rowsOption: integer | nil = options.maxRows
  if rowsOption ~= nil then maxRows = rowsOption! end
  local fieldsOption: integer | nil = options.maxFields
  if fieldsOption ~= nil then maxFields = fieldsOption! end
  local fieldBytesOption: integer | nil = options.maxFieldBytes
  if fieldBytesOption ~= nil then maxFieldBytes = fieldBytesOption! end
  validateDelimiter(delimiter)
  if maxBytes < 0 or maxRows < 0 or maxFields < 1 or maxFieldBytes < 0 then
    error("invalid CSV limits")
  end
  if #text > maxBytes then
    return {
      ok = false, rows = {}, error = "CSV input exceeds maxBytes",
      row = 1, column = 1,
    }
  end

  local rows: string[][] = {}
  local row: string[] = {}
  local field: string[] = {}
  local state: integer = S_START
  local rowNumber: integer = 1
  local column: integer = 1

  local function fail(message: string): CsvResult
    return {
      ok = false,
      rows = rows,
      error = message,
      row = rowNumber,
      column = column,
    }
  end

  local function pushField(): boolean
    local value: string = table.concat(field)
    if #value > maxFieldBytes then
      fail("CSV field exceeds maxFieldBytes")
      return false
    end
    row[#row + 1] = value
    field = {}
    column = column + 1
    return true
  end

  local function finishRow(): boolean
    if #row > maxFields then
      fail("CSV row exceeds maxFields")
      return false
    end
    rows[#rows + 1] = row
    if #rows > maxRows then
      fail("CSV input exceeds maxRows")
      return false
    end
    row = {}
    rowNumber = rowNumber + 1
    column = 1
    return true
  end

  local i: integer = 1
  while i <= #text do
    local c: string = string.sub(text, i, i)
    if state == S_START then
      if c == "\"" then
        state = S_QUOTED
        field = {}
        i = i + 1
      elseif c == delimiter then
        if not pushField() then return fail("CSV field limit") end
        i = i + 1
      elseif c == "\r" then
        if i + 1 > #text or string.sub(text, i + 1, i + 1) ~= "\n" then
          return fail("bare CR outside quoted CSV field")
        end
        if not pushField() then return fail("CSV field limit") end
        if not finishRow() then return fail("CSV row limit") end
        i = i + 2
      elseif c == "\n" then
        if not pushField() then return fail("CSV field limit") end
        if not finishRow() then return fail("CSV row limit") end
        i = i + 1
      else
        state = S_UNQUOTED
        field = { c }
        i = i + 1
      end
    elseif state == S_UNQUOTED then
      if c == delimiter then
        if not pushField() then return fail("CSV field limit") end
        state = S_START
        i = i + 1
      elseif c == "\r" then
        if i + 1 > #text or string.sub(text, i + 1, i + 1) ~= "\n" then
          return fail("bare CR outside quoted CSV field")
        end
        if not pushField() then return fail("CSV field limit") end
        if not finishRow() then return fail("CSV row limit") end
        state = S_START
        i = i + 2
      elseif c == "\n" then
        if not pushField() then return fail("CSV field limit") end
        if not finishRow() then return fail("CSV row limit") end
        state = S_START
        i = i + 1
      elseif c == "\"" then
        return fail("quote inside unquoted CSV field")
      else
        field[#field + 1] = c
        i = i + 1
      end
    elseif state == S_QUOTED then
      if c == "\"" then
        state = S_AFTER_QUOTE
      else
        field[#field + 1] = c
      end
      i = i + 1
    else
      -- S_AFTER_QUOTE
      if c == "\"" then
        field[#field + 1] = "\""
        state = S_QUOTED
        i = i + 1
      elseif c == delimiter then
        if not pushField() then return fail("CSV field limit") end
        state = S_START
        i = i + 1
      elseif c == "\r" then
        if i + 1 > #text or string.sub(text, i + 1, i + 1) ~= "\n" then
          return fail("bare CR outside quoted CSV field")
        end
        if not pushField() then return fail("CSV field limit") end
        if not finishRow() then return fail("CSV row limit") end
        state = S_START
        i = i + 2
      elseif c == "\n" then
        if not pushField() then return fail("CSV field limit") end
        if not finishRow() then return fail("CSV row limit") end
        state = S_START
        i = i + 1
      else
        return fail("character after closing CSV quote")
      end
    end
  end

  if state == S_QUOTED then
    return fail("unterminated quoted CSV field")
  elseif state == S_UNQUOTED or state == S_AFTER_QUOTE then
    if not pushField() then return fail("CSV field limit") end
    if not finishRow() then return fail("CSV row limit") end
  elseif #row > 0 then
    -- A trailing delimiter leaves one final empty field.
    if not pushField() then return fail("CSV field limit") end
    if not finishRow() then return fail("CSV row limit") end
  end
  return { ok = true, rows = rows, error = "", row = rowNumber, column = column }
end

local function parse(text: string): CsvResult
  return parseWith(text, {
    delimiter = ",",
    maxBytes = DEFAULT_MAX_BYTES,
    maxRows = DEFAULT_MAX_ROWS,
    maxFields = DEFAULT_MAX_FIELDS,
    maxFieldBytes = DEFAULT_MAX_FIELD_BYTES,
  })
end

local function quoteField(value: string, delimiter: string): string
  local needsQuote: boolean = false
  for i: integer = 1, #value do
    local c: string = string.sub(value, i, i)
    if c == delimiter or c == "\"" or c == "\r" or c == "\n" then
      needsQuote = true
      break
    end
  end
  if not needsQuote then return value end
  local out: string[] = { "\"" }
  for i: integer = 1, #value do
    local c: string = string.sub(value, i, i)
    if c == "\"" then out[#out + 1] = "\"\"" else out[#out + 1] = c end
  end
  out[#out + 1] = "\""
  return table.concat(out)
end

local function encodeWith(rows: string[][], options: CsvEncodeOptions): string
  local delimiter: string = ","
  local delimiterOption: string | nil = options.delimiter
  if delimiterOption ~= nil then delimiter = delimiterOption! end
  validateDelimiter(delimiter)
  local records: string[] = {}
  for i: integer = 1, #rows do
    local fields: string[] = rows[i]
    local encoded: string[] = {}
    for j: integer = 1, #fields do
      encoded[#encoded + 1] = quoteField(fields[j], delimiter)
    end
    records[#records + 1] = table.concat(encoded, delimiter)
  end
  return table.concat(records, "\r\n")
end

local function encode(rows: string[][]): string
  return encodeWith(rows, { delimiter = "," })
end

return {
  parse = parse,
  parseWith = parseWith,
  encode = encode,
  encodeWith = encodeWith,
}
