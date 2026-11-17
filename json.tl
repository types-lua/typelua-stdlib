--- Strict JSON encoder/decoder.
---
--- `decode` returns a result record; malformed input never throws. `null` is
--- represented by the exported `null` sentinel (not Lua `nil`), so arrays and
--- objects can contain null without creating holes. Encoding `nil` also emits
--- JSON null for convenience.
---
--- Objects are Lua tables with string keys. Arrays are tables whose keys are
--- exactly the contiguous integers 1..n. Empty tables encode as `{}`; use an
--- explicit array value from your application when an empty `[]` is required.
--- Encoding rejects cycles, mixed/sparse numeric keys, non-string object keys
--- and non-finite numbers.

type JsonDecodeOptions = {
  maxDepth?: integer,
  maxBytes?: integer,
}

type JsonDecodeResult = {
  ok: boolean,
  value: any,
  error: string,
  position: integer,
}

type JsonEncodeResult = {
  ok: boolean,
  text: string,
  error: string,
}

class JsonNull {
  constructor() end,
}

local NULL: JsonNull = JsonNull.new()

local function isNull(value: any): boolean
  return value == NULL
end

local function appendUtf8(codepoint: integer): string
  if codepoint <= 0x7F then
    return string.char(codepoint)
  elseif codepoint <= 0x7FF then
    local b1: integer = math.floor(0xC0 + codepoint / 64)
    local b2: integer = math.floor(0x80 + codepoint % 64)
    return string.char(b1, b2)
  elseif codepoint <= 0xFFFF then
    local b1: integer = math.floor(0xE0 + codepoint / 4096)
    local b2: integer = math.floor(0x80 + (codepoint / 64) % 64)
    local b3: integer = math.floor(0x80 + codepoint % 64)
    return string.char(b1, b2, b3)
  end
  local b1: integer = math.floor(0xF0 + codepoint / 262144)
  local b2: integer = math.floor(0x80 + (codepoint / 4096) % 64)
  local b3: integer = math.floor(0x80 + (codepoint / 64) % 64)
  local b4: integer = math.floor(0x80 + codepoint % 64)
  return string.char(b1, b2, b3, b4)
end

local function hexValue(byte: integer): integer
  if byte >= 48 and byte <= 57 then return byte - 48 end
  if byte >= 65 and byte <= 70 then return byte - 55 end
  if byte >= 97 and byte <= 102 then return byte - 87 end
  return -1
end

class Parser {
  text: string,
  pos: integer = 1,
  depth: integer = 0,
  maxDepth: integer = 512,
  failed: boolean = false,
  errorText: string = "",
  errorPosition: integer = 1,

  constructor(text: string, options: JsonDecodeOptions)
    self.text = text
    local maxDepth: integer | nil = options.maxDepth
    if maxDepth ~= nil then self.maxDepth = maxDepth! end
    if self.maxDepth < 1 then error("JSON maxDepth must be >= 1") end
    self.pos = 1
  end,

  fail(message: string, position: integer): void
    if not self.failed then
      self.failed = true
      self.errorText = message
      self.errorPosition = position
    end
  end,

  skipWhitespace(): void
    while self.pos <= #self.text do
      local byte: integer = string.byte(self.text, self.pos)!
      if byte == 32 or byte == 9 or byte == 10 or byte == 13 then
        self.pos = self.pos + 1
      else
        break
      end
    end
  end,

  parseHex4(): integer
    if self.pos + 3 > #self.text then
      self:fail("truncated \\u escape", self.pos)
      return -1
    end
    local value: integer = 0
    for i: integer = 0, 3 do
      local digit: integer = hexValue(string.byte(self.text, self.pos + i)!)
      if digit < 0 then
        self:fail("invalid \\u escape", self.pos)
        return -1
      end
      value = value * 16 + digit
    end
    self.pos = self.pos + 4
    return value
  end,

  parseString(): string
    if string.sub(self.text, self.pos, self.pos) ~= "\"" then
      self:fail("expected a string", self.pos)
      return ""
    end
    self.pos = self.pos + 1
    local out: string[] = {}
    while self.pos <= #self.text do
      local byte: integer = string.byte(self.text, self.pos)!
      if byte == 34 then
        self.pos = self.pos + 1
        return table.concat(out)
      elseif byte == 92 then
        self.pos = self.pos + 1
        if self.pos > #self.text then
          self:fail("truncated escape", self.pos)
          return ""
        end
        local escape: string = string.sub(self.text, self.pos, self.pos)
        self.pos = self.pos + 1
        if escape == "\"" then out[#out + 1] = "\""
        elseif escape == "\\" then out[#out + 1] = "\\"
        elseif escape == "/" then out[#out + 1] = "/"
        elseif escape == "b" then out[#out + 1] = "\b"
        elseif escape == "f" then out[#out + 1] = "\f"
        elseif escape == "n" then out[#out + 1] = "\n"
        elseif escape == "r" then out[#out + 1] = "\r"
        elseif escape == "t" then out[#out + 1] = "\t"
        elseif escape == "u" then
          local codepoint: integer = self:parseHex4()
          if self.failed then return "" end
          if codepoint >= 0xD800 and codepoint <= 0xDBFF then
            if string.sub(self.text, self.pos, self.pos + 1) ~= "\\u" then
              self:fail("high surrogate without low surrogate", self.pos)
              return ""
            end
            self.pos = self.pos + 2
            local low: integer = self:parseHex4()
            if self.failed then return "" end
            if low < 0xDC00 or low > 0xDFFF then
              self:fail("invalid low surrogate", self.pos)
              return ""
            end
            codepoint = 0x10000 + (codepoint - 0xD800) * 1024 + (low - 0xDC00)
          elseif codepoint >= 0xDC00 and codepoint <= 0xDFFF then
            self:fail("unexpected low surrogate", self.pos)
            return ""
          end
          out[#out + 1] = appendUtf8(codepoint)
        else
          self:fail("invalid escape", self.pos)
          return ""
        end
      elseif byte < 32 then
        self:fail("control character in string", self.pos)
        return ""
      else
        out[#out + 1] = string.sub(self.text, self.pos, self.pos)
        self.pos = self.pos + 1
      end
    end
    self:fail("unterminated string", self.pos)
    return ""
  end,

  parseNumber(): number
    local start: integer = self.pos
    if string.sub(self.text, self.pos, self.pos) == "-" then
      self.pos = self.pos + 1
    end
    if self.pos > #self.text then
      self:fail("truncated number", start)
      return 0
    end
    local first: string = string.sub(self.text, self.pos, self.pos)
    if first == "0" then
      self.pos = self.pos + 1
      if self.pos <= #self.text then
        local nextByte: integer = string.byte(self.text, self.pos)!
        if nextByte >= 48 and nextByte <= 57 then
          self:fail("leading zero in number", self.pos - 1)
          return 0
        end
      end
    elseif first >= "1" and first <= "9" then
      while self.pos <= #self.text do
        local byte: integer = string.byte(self.text, self.pos)!
        if byte < 48 or byte > 57 then break end
        self.pos = self.pos + 1
      end
    else
      self:fail("invalid number", self.pos)
      return 0
    end
    if self.pos <= #self.text and string.sub(self.text, self.pos, self.pos) == "." then
      self.pos = self.pos + 1
      local digitStart: integer = self.pos
      while self.pos <= #self.text do
        local byte: integer = string.byte(self.text, self.pos)!
        if byte < 48 or byte > 57 then break end
        self.pos = self.pos + 1
      end
      if self.pos == digitStart then
        self:fail("missing fraction digits", self.pos)
        return 0
      end
    end
    if self.pos <= #self.text then
      local marker: string = string.sub(self.text, self.pos, self.pos)
      if marker == "e" or marker == "E" then
        self.pos = self.pos + 1
        if self.pos <= #self.text then
          local sign: string = string.sub(self.text, self.pos, self.pos)
          if sign == "+" or sign == "-" then self.pos = self.pos + 1 end
        end
        local digitStart: integer = self.pos
        while self.pos <= #self.text do
          local byte: integer = string.byte(self.text, self.pos)!
          if byte < 48 or byte > 57 then break end
          self.pos = self.pos + 1
        end
        if self.pos == digitStart then
          self:fail("missing exponent digits", self.pos)
          return 0
        end
      end
    end
    local text: string = string.sub(self.text, start, self.pos - 1)
    local value: number | nil = tonumber(text)
    if value == nil then
      self:fail("invalid number", start)
      return 0
    end
    local numberValue: number = value!
    if numberValue ~= numberValue
      or numberValue == math.huge or numberValue == -math.huge then
      self:fail("number is not finite", start)
      return 0
    end
    return numberValue
  end,

  parseArray(): any[]
    self.pos = self.pos + 1
    self.depth = self.depth + 1
    if self.depth > self.maxDepth then
      self:fail("maximum JSON depth exceeded", self.pos)
      return {}
    end
    local out: any[] = {}
    self:skipWhitespace()
    if self.pos <= #self.text and string.sub(self.text, self.pos, self.pos) == "]" then
      self.pos = self.pos + 1
      self.depth = self.depth - 1
      return out
    end
    while true do
      local value: any = self:parseValue()
      if self.failed then return out end
      out[#out + 1] = value
      self:skipWhitespace()
      if self.pos > #self.text then
        self:fail("unterminated array", self.pos)
        return out
      end
      local marker: string = string.sub(self.text, self.pos, self.pos)
      if marker == "]" then
        self.pos = self.pos + 1
        self.depth = self.depth - 1
        return out
      elseif marker ~= "," then
        self:fail("expected ',' or ']'", self.pos)
        return out
      end
      self.pos = self.pos + 1
      self:skipWhitespace()
    end
  end,

  parseObject(): map<string, any>
    self.pos = self.pos + 1
    self.depth = self.depth + 1
    if self.depth > self.maxDepth then
      self:fail("maximum JSON depth exceeded", self.pos)
      return {}
    end
    local out: map<string, any> = {}
    self:skipWhitespace()
    if self.pos <= #self.text and string.sub(self.text, self.pos, self.pos) == "}" then
      self.pos = self.pos + 1
      self.depth = self.depth - 1
      return out
    end
    while true do
      self:skipWhitespace()
      if self.pos > #self.text or string.sub(self.text, self.pos, self.pos) ~= "\"" then
        self:fail("object key must be a string", self.pos)
        return out
      end
      local key: string = self:parseString()
      if self.failed then return out end
      self:skipWhitespace()
      if self.pos > #self.text or string.sub(self.text, self.pos, self.pos) ~= ":" then
        self:fail("expected ':' after object key", self.pos)
        return out
      end
      self.pos = self.pos + 1
      self:skipWhitespace()
      local value: any = self:parseValue()
      if self.failed then return out end
      out[key] = value
      self:skipWhitespace()
      if self.pos > #self.text then
        self:fail("unterminated object", self.pos)
        return out
      end
      local marker: string = string.sub(self.text, self.pos, self.pos)
      if marker == "}" then
        self.pos = self.pos + 1
        self.depth = self.depth - 1
        return out
      elseif marker ~= "," then
        self:fail("expected ',' or '}'", self.pos)
        return out
      end
      self.pos = self.pos + 1
    end
  end,

  parseValue(): any
    if self.failed then return nil end
    self:skipWhitespace()
    if self.pos > #self.text then
      self:fail("unexpected end of input", self.pos)
      return nil
    end
    local marker: string = string.sub(self.text, self.pos, self.pos)
    if marker == "\"" then return self:parseString() end
    if marker == "{" then return self:parseObject() end
    if marker == "[" then return self:parseArray() end
    if marker == "t" then
      if string.sub(self.text, self.pos, self.pos + 3) ~= "true" then
        self:fail("invalid literal", self.pos)
        return nil
      end
      self.pos = self.pos + 4
      return true
    end
    if marker == "f" then
      if string.sub(self.text, self.pos, self.pos + 4) ~= "false" then
        self:fail("invalid literal", self.pos)
        return nil
      end
      self.pos = self.pos + 5
      return false
    end
    if marker == "n" then
      if string.sub(self.text, self.pos, self.pos + 3) ~= "null" then
        self:fail("invalid literal", self.pos)
        return nil
      end
      self.pos = self.pos + 4
      return NULL
    end
    if marker == "-" or (marker >= "0" and marker <= "9") then
      return self:parseNumber()
    end
    self:fail("unexpected character", self.pos)
    return nil
  end,

  parse(): JsonDecodeResult
    if self.failed then
      return {
        ok = false,
        value = nil,
        error = self.errorText,
        position = self.errorPosition,
      }
    end
    local value: any = self:parseValue()
    if self.failed then
      return {
        ok = false,
        value = nil,
        error = self.errorText,
        position = self.errorPosition,
      }
    end
    self:skipWhitespace()
    if self.pos <= #self.text then
      return {
        ok = false,
        value = nil,
        error = "trailing characters after JSON value",
        position = self.pos,
      }
    end
    return { ok = true, value = value, error = "", position = self.pos }
  end,
}

class Encoder {
  pretty: boolean,
  indent: string,
  seen: any = {},
  failed: boolean = false,
  errorText: string = "",
  parts: string[] = {},

  constructor(pretty: boolean, indentSize: integer)
    self.pretty = pretty
    if indentSize < 0 or indentSize > 16 then
      error("JSON indent must be 0..16")
    end
    self.indent = string.rep(" ", indentSize)
  end,

  fail(message: string): void
    if not self.failed then
      self.failed = true
      self.errorText = message
    end
  end,

  emit(text: string): void
    self.parts[#self.parts + 1] = text
  end,

  newline(level: integer): void
    if self.pretty then
      self:emit("\n" .. string.rep(self.indent, level))
    end
  end,

  escape(text: string): string
    local out: string[] = { "\"" }
    for i: integer = 1, #text do
      local byte: integer = string.byte(text, i)!
      if byte == 34 then out[#out + 1] = "\\\""
      elseif byte == 92 then out[#out + 1] = "\\\\"
      elseif byte == 8 then out[#out + 1] = "\\b"
      elseif byte == 12 then out[#out + 1] = "\\f"
      elseif byte == 10 then out[#out + 1] = "\\n"
      elseif byte == 13 then out[#out + 1] = "\\r"
      elseif byte == 9 then out[#out + 1] = "\\t"
      elseif byte < 32 then
        local high: integer = math.floor(byte / 16 + 1)
        local low: integer = math.floor(byte % 16 + 1)
        out[#out + 1] = "\\u00"
          .. string.sub("0123456789abcdef", high, high)
          .. string.sub("0123456789abcdef", low, low)
      else
        out[#out + 1] = string.sub(text, i, i)
      end
    end
    out[#out + 1] = "\""
    return table.concat(out)
  end,

  isArray(value: any, keys: any[]): boolean
    local numeric: integer = 0
    local maxIndex: integer = 0
    local strings: integer = 0
    for i: integer = 1, #keys do
      local key: any = keys[i]
      if type(key) == "number" and key >= 1 and math.floor(key) == key then
        numeric = numeric + 1
        local index: integer = key as integer
        if index > maxIndex then maxIndex = index end
      elseif type(key) == "string" then
        strings = strings + 1
      else
        self:fail("JSON object keys must be strings")
        return false
      end
    end
    if numeric == 0 and strings == 0 then return false end
    if strings > 0 and numeric > 0 then
      self:fail("JSON table mixes array and object keys")
      return false
    end
    if strings > 0 then return false end
    if numeric ~= maxIndex then
      self:fail("JSON array is sparse")
      return false
    end
    return true
  end,

  encodeValue(value: any, level: integer): void
    if self.failed then return end
    if value == nil or value == NULL then
      self:emit("null")
      return
    end
    local kind: string = type(value)
    if kind == "boolean" then
      if value then self:emit("true") else self:emit("false") end
      return
    elseif kind == "number" then
      if value ~= value or value == math.huge or value == -math.huge then
        self:fail("JSON cannot encode a non-finite number")
        return
      end
      local text: string = string.format("%.17g", value)
      self:emit(string.gsub(text, ",", "."))
      return
    elseif kind == "string" then
      self:emit(self:escape(value))
      return
    elseif kind ~= "table" then
      self:fail("JSON cannot encode a " .. kind)
      return
    end

    if self.seen[value] then
      self:fail("JSON cannot encode a cyclic table")
      return
    end
    self.seen[value] = true
    local rawKeys: any[] = {}
    for key, _ in pairs(value) do
      rawKeys[#rawKeys + 1] = key
    end
    local arrayLike: boolean = self:isArray(value, rawKeys)
    if self.failed then
      self.seen[value] = nil
      return
    end
    if arrayLike then
      if #rawKeys == 0 then
        self:emit("[]")
      else
        self:emit("[")
        table.sort(rawKeys, function(a: number, b: number): boolean return a < b end)
        for i: integer = 1, #rawKeys do
          if i > 1 then self:emit(",") end
          self:newline(level + 1)
          self:encodeValue(value[rawKeys[i]], level + 1)
          if self.failed then
            self.seen[value] = nil
            return
          end
        end
        self:newline(level)
        self:emit("]")
      end
    else
      if #rawKeys == 0 then
        self:emit("{}")
      else
        local stringKeys: string[] = {}
        for i: integer = 1, #rawKeys do
          stringKeys[#stringKeys + 1] = rawKeys[i] as string
        end
        table.sort(stringKeys, function(a: string, b: string): boolean return a < b end)
        self:emit("{")
        for i: integer = 1, #stringKeys do
          if i > 1 then self:emit(",") end
          self:newline(level + 1)
          self:emit(self:escape(stringKeys[i]))
          self:emit(":")
          if self.pretty then self:emit(" ") end
          self:encodeValue(value[stringKeys[i]], level + 1)
          if self.failed then
            self.seen[value] = nil
            return
          end
        end
        self:newline(level)
        self:emit("}")
      end
    end
    self.seen[value] = nil
  end,

  encode(value: any): JsonEncodeResult
    self:encodeValue(value, 0)
    if self.failed then
      return { ok = false, text = "", error = self.errorText }
    end
    return { ok = true, text = table.concat(self.parts), error = "" }
  end,
}

local DEFAULT_MAX_DEPTH: integer = 512
local DEFAULT_MAX_BYTES: integer = 8 * 1024 * 1024

local function decodeWith(text: string, options: JsonDecodeOptions): JsonDecodeResult
  local maxDepth: integer = DEFAULT_MAX_DEPTH
  local maxBytes: integer = DEFAULT_MAX_BYTES
  local depthOption: integer | nil = options.maxDepth
  if depthOption ~= nil then maxDepth = depthOption! end
  local bytesOption: integer | nil = options.maxBytes
  if bytesOption ~= nil then maxBytes = bytesOption! end
  if maxBytes < 0 then error("JSON maxBytes must be >= 0") end
  if #text > maxBytes then
    return {
      ok = false,
      value = nil,
      error = "JSON input exceeds maxBytes",
      position = 1,
    }
  end
  local parser = Parser.new(text, { maxDepth = maxDepth })
  return parser:parse()
end

local function decode(text: string): JsonDecodeResult
  return decodeWith(text, { maxDepth = DEFAULT_MAX_DEPTH, maxBytes = DEFAULT_MAX_BYTES })
end

local function encodeResult(value: any): JsonEncodeResult
  local encoder = Encoder.new(false, 0)
  return encoder:encode(value)
end

local function encode(value: any): string
  local result: JsonEncodeResult = encodeResult(value)
  if not result.ok then error("JSON encode: " .. result.error) end
  return result.text
end

local function encodePrettyResult(value: any, indent: integer): JsonEncodeResult
  local encoder = Encoder.new(true, indent)
  return encoder:encode(value)
end

local function encodePretty(value: any, indent: integer): string
  local result: JsonEncodeResult = encodePrettyResult(value, indent)
  if not result.ok then error("JSON encode: " .. result.error) end
  return result.text
end

return {
  null = NULL,
  isNull = isNull,
  JsonNull = JsonNull,
  decode = decode,
  decodeWith = decodeWith,
  encode = encode,
  encodeResult = encodeResult,
  encodePretty = encodePretty,
  encodePrettyResult = encodePrettyResult,
}
