--- UTC calendar/time helpers.
---
--- Timestamps are Unix seconds (number; fractional seconds are accepted where
--- documented). The module uses its own proleptic-Gregorian civil-date math, so
--- results do not depend on the process timezone or locale. `formatUtc` is the
--- only function that delegates formatting to `os.date`, always with the `!`
--- UTC prefix.

type DateParts = {
  year: integer,
  month: integer,
  day: integer,
  hour: integer,
  minute: integer,
  second: integer,
  weekday: integer, -- 0 = Sunday .. 6 = Saturday
  yday: integer,   -- 1-based day of year
}

type TimePartsInput = {
  year: integer,
  month: integer,
  day: integer,
  hour: integer,
  minute: integer,
  second: integer,
}

type TimeResult = {
  ok: boolean,
  timestamp: number,
  error: string,
}

local SECONDS_PER_DAY: integer = 86400

local function toInt(value: string): integer
  local numberValue: number | nil = tonumber(value)
  if numberValue == nil then error("invalid integer: " .. value) end
  return math.floor(numberValue!)
end

local function isLeapYear(year: integer): boolean
  return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function daysInMonth(year: integer, month: integer): integer
  if month < 1 or month > 12 then error("month must be 1..12") end
  if month == 2 then
    if isLeapYear(year) then return 29 end
    return 28
  end
  if month == 4 or month == 6 or month == 9 or month == 11 then return 30 end
  return 31
end

-- Howard Hinnant's civil calendar algorithms.
local function daysFromCivil(year: integer, month: integer, day: integer): integer
  local y: integer = year
  if month <= 2 then y = y - 1 end
  local era: integer = math.floor(y / 400)
  local yoe: integer = y - era * 400
  local shiftedMonth: integer = month
  if month > 2 then shiftedMonth = month - 3 else shiftedMonth = month + 9 end
  local doy: integer = math.floor((153 * shiftedMonth + 2) / 5 + day - 1)
  local doe: integer = math.floor(yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy)
  return era * 146097 + doe - 719468
end

local function civilFromDays(days: integer): (integer, integer, integer)
  local z: integer = days + 719468
  local era: integer = math.floor(z / 146097)
  local doe: integer = z - era * 146097
  local yoe: integer = math.floor(
    (doe - math.floor(doe / 1460) + math.floor(doe / 36524)
      - math.floor(doe / 146096)) / 365
  )
  local year: integer = yoe + era * 400
  local doy: integer = math.floor(doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100)))
  local mp: integer = math.floor((5 * doy + 2) / 153)
  local day: integer = math.floor(doy - math.floor((153 * mp + 2) / 5) + 1)
  local month: integer = mp
  if mp < 10 then month = mp + 3 else month = mp - 9 end
  if month <= 2 then year = year + 1 end
  return year, month, day
end

local function now(): integer
  return os.time()
end

local function formatUtc(timestamp: number, pattern: string): string
  local value: any = os.date("!" .. pattern, math.floor(timestamp))
  if value == nil then return "" end
  return tostring(value)
end

local function iso8601(timestamp: number): string
  return formatUtc(timestamp, "%Y-%m-%dT%H:%M:%SZ")
end

local function dateParts(timestamp: number): DateParts
  local whole: integer = math.floor(timestamp)
  local days: integer = math.floor(whole / SECONDS_PER_DAY)
  local remainder: integer = whole - days * SECONDS_PER_DAY
  if remainder < 0 then
    remainder = remainder + SECONDS_PER_DAY
    days = days - 1
  end
  local year, month, day = civilFromDays(days)
  local hour: integer = math.floor(remainder / 3600)
  local minute: integer = math.floor((remainder % 3600) / 60)
  local second: integer = remainder % 60
  local weekday: integer = (days + 4) % 7
  if weekday < 0 then weekday = weekday + 7 end
  local yday: integer = days - daysFromCivil(year, 1, 1) + 1
  return {
    year = year,
    month = month,
    day = day,
    hour = hour,
    minute = minute,
    second = second,
    weekday = weekday,
    yday = yday,
  }
end

local function fromParts(parts: TimePartsInput): TimeResult
  if parts.month < 1 or parts.month > 12 then
    return { ok = false, timestamp = 0, error = "month must be 1..12" }
  end
  if parts.day < 1 or parts.day > daysInMonth(parts.year, parts.month) then
    return { ok = false, timestamp = 0, error = "invalid day for month" }
  end
  if parts.hour < 0 or parts.hour > 23
    or parts.minute < 0 or parts.minute > 59
    or parts.second < 0 or parts.second > 59 then
    return { ok = false, timestamp = 0, error = "invalid time of day" }
  end
  local days: integer = daysFromCivil(parts.year, parts.month, parts.day)
  local timestamp: integer = days * SECONDS_PER_DAY
    + parts.hour * 3600 + parts.minute * 60 + parts.second
  return { ok = true, timestamp = timestamp, error = "" }
end

local function parseIso8601(text: string): TimeResult
  local yearText, monthText, dayText, rest =
    string.match(text, "^(%d%d%d%d)%-(%d%d)%-(%d%d)(.*)$")
  if yearText == nil or monthText == nil or dayText == nil or rest == nil then
    return { ok = false, timestamp = 0, error = "expected YYYY-MM-DD" }
  end
  local year: integer = toInt(yearText!)
  local month: integer = toInt(monthText!)
  local day: integer = toInt(dayText!)
  local remaining: string = rest!
  local hour: integer = 0
  local minute: integer = 0
  local second: integer = 0
  local fraction: number = 0
  local offsetSeconds: integer = 0

  if remaining ~= "" then
    local marker: string = string.sub(remaining, 1, 1)
    if marker ~= "T" and marker ~= "t" and marker ~= " " then
      return { ok = false, timestamp = 0, error = "expected T after date" }
    end
    remaining = string.sub(remaining, 2)
    local hText, mText, sText, tail =
      string.match(remaining, "^(%d%d):(%d%d):(%d%d)(.*)$")
    if hText == nil or mText == nil or sText == nil or tail == nil then
      return { ok = false, timestamp = 0, error = "expected HH:MM:SS" }
    end
    hour = toInt(hText!)
    minute = toInt(mText!)
    second = toInt(sText!)
    remaining = tail!
    if string.sub(remaining, 1, 1) == "." then
      local digits, rest2 = string.match(remaining, "^%.(%d+)(.*)$")
      if digits == nil or rest2 == nil then
        return { ok = false, timestamp = 0, error = "invalid fractional seconds" }
      end
      fraction = tonumber("0." .. digits!)!
      remaining = rest2!
    end
    if remaining ~= "" then
      if remaining == "Z" or remaining == "z" then
        remaining = ""
      else
        local signText, hoursText, minutesText =
          string.match(remaining, "^([%+%-])(%d%d):(%d%d)$")
        if signText == nil or hoursText == nil or minutesText == nil then
          return { ok = false, timestamp = 0, error = "invalid timezone offset" }
        end
        local offsetHours: integer = toInt(hoursText!)
        local offsetMinutes: integer = toInt(minutesText!)
        if offsetHours > 23 or offsetMinutes > 59 then
          return { ok = false, timestamp = 0, error = "invalid timezone offset" }
        end
        offsetSeconds = offsetHours * 3600 + offsetMinutes * 60
        if signText! == "-" then offsetSeconds = -offsetSeconds end
        remaining = ""
      end
    end
  end
  if remaining ~= "" then
    return { ok = false, timestamp = 0, error = "trailing characters" }
  end
  local base: TimeResult = fromParts({
    year = year,
    month = month,
    day = day,
    hour = hour,
    minute = minute,
    second = second,
  })
  if not base.ok then return base end
  return {
    ok = true,
    timestamp = base.timestamp - offsetSeconds + fraction,
    error = "",
  }
end

local function addSeconds(timestamp: number, seconds: number): number
  return timestamp + seconds
end

local function addDays(timestamp: number, days: integer): number
  return timestamp + days * SECONDS_PER_DAY
end

local function startOfDayUtc(timestamp: number): number
  local whole: integer = math.floor(timestamp)
  local days: integer = math.floor(whole / SECONDS_PER_DAY)
  return days * SECONDS_PER_DAY
end

local function endOfDayUtc(timestamp: number): number
  return startOfDayUtc(timestamp) + SECONDS_PER_DAY - 1
end

local function weekday(timestamp: number): integer
  local parts: DateParts = dateParts(timestamp)
  return parts.weekday
end

local function isoWeekday(timestamp: number): integer
  local value: integer = weekday(timestamp)
  if value == 0 then return 7 end
  return value
end

local function duration(seconds: integer): string
  local value: integer = seconds
  local sign: string = ""
  if value < 0 then
    sign = "-"
    value = -value
  end
  if value == 0 then return "0s" end
  local days: integer = math.floor(value / SECONDS_PER_DAY)
  local hours: integer = math.floor((value % SECONDS_PER_DAY) / 3600)
  local minutes: integer = math.floor((value % 3600) / 60)
  local secs: integer = value % 60
  local out: string[] = {}
  if days > 0 then out[#out + 1] = tostring(days) .. "d" end
  if hours > 0 then out[#out + 1] = tostring(hours) .. "h" end
  if minutes > 0 then out[#out + 1] = tostring(minutes) .. "m" end
  if secs > 0 then out[#out + 1] = tostring(secs) .. "s" end
  return sign .. table.concat(out, " ")
end

return {
  SECONDS_PER_DAY = SECONDS_PER_DAY,
  now = now,
  isLeapYear = isLeapYear,
  daysInMonth = daysInMonth,
  dateParts = dateParts,
  fromParts = fromParts,
  parseIso8601 = parseIso8601,
  formatUtc = formatUtc,
  iso8601 = iso8601,
  addSeconds = addSeconds,
  addDays = addDays,
  startOfDayUtc = startOfDayUtc,
  endOfDayUtc = endOfDayUtc,
  weekday = weekday,
  isoWeekday = isoWeekday,
  duration = duration,
}
