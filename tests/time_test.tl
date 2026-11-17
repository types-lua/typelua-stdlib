import T from "tlua_test"
import time from "../time"

return {
  ["leap years and month lengths"] = function(): void
    T.ok(time.isLeapYear(2000), "2000 leap")
    T.ok(not time.isLeapYear(1900), "1900 not leap")
    T.ok(time.isLeapYear(2024), "2024 leap")
    T.ok(not time.isLeapYear(2023), "2023 not leap")
    T.eq(time.daysInMonth(2024, 2), 29, "feb leap")
    T.eq(time.daysInMonth(2023, 2), 28, "feb normal")
    T.eq(time.daysInMonth(2023, 4), 30, "april")
    T.eq(time.daysInMonth(2023, 12), 31, "december")
    T.raises(function(): void time.daysInMonth(2023, 13) end)
  end,

  ["epoch and date parts"] = function(): void
    local epoch = time.dateParts(0)
    T.eq(epoch.year, 1970, "epoch year")
    T.eq(epoch.month, 1, "epoch month")
    T.eq(epoch.day, 1, "epoch day")
    T.eq(epoch.hour, 0, "epoch hour")
    T.eq(epoch.weekday, 4, "epoch Thursday")
    T.eq(epoch.yday, 1, "epoch yday")
    local previous = time.dateParts(-1)
    T.eq(previous.year, 1969, "negative year")
    T.eq(previous.month, 12, "negative month")
    T.eq(previous.day, 31, "negative day")
    T.eq(previous.hour, 23, "negative hour")
    T.eq(previous.minute, 59, "negative minute")
    T.eq(previous.second, 59, "negative second")
    local leapDay = time.dateParts(951782400)
    T.eq(leapDay.year, 2000, "leap day year")
    T.eq(leapDay.month, 2, "leap day month")
    T.eq(leapDay.day, 29, "leap day")
    T.eq(time.iso8601(0), "1970-01-01T00:00:00Z", "epoch ISO")
    T.eq(time.iso8601(951782400), "2000-02-29T00:00:00Z", "leap ISO")
  end,

  ["fromParts and parseIso8601"] = function(): void
    local result = time.fromParts({
      year = 2024, month = 2, day = 29,
      hour = 12, minute = 34, second = 56,
      weekday = 0, yday = 0,
    })
    T.ok(result.ok, "fromParts ok")
    local parts = time.dateParts(result.timestamp)
    T.eq(parts.year, 2024, "round-trip year")
    T.eq(parts.month, 2, "round-trip month")
    T.eq(parts.day, 29, "round-trip day")
    T.eq(parts.hour, 12, "round-trip hour")
    T.eq(parts.minute, 34, "round-trip minute")
    T.eq(parts.second, 56, "round-trip second")

    T.eq(time.parseIso8601("1970-01-01").timestamp, 0, "date only")
    T.eq(time.parseIso8601("1970-01-01T00:00:00Z").timestamp, 0, "Z")
    T.eq(time.parseIso8601("1970-01-01T00:00:00+01:00").timestamp, -3600, "positive offset")
    T.eq(time.parseIso8601("1970-01-01T00:00:00-01:00").timestamp, 3600, "negative offset")
    T.eq(time.parseIso8601("1970-01-01T00:00:00.500Z").timestamp, 0.5, "fraction")
    T.ok(not time.parseIso8601("2019-02-29").ok, "invalid leap day")
    T.ok(not time.parseIso8601("2023-13-01").ok, "invalid month")
    T.ok(not time.parseIso8601("2023-01-00").ok, "invalid day")
    T.ok(not time.parseIso8601("2023-01-01T24:00:00Z").ok, "invalid hour")
    T.ok(not time.parseIso8601("2023-01-01T00:00:00+24:00").ok, "invalid offset")
    T.ok(not time.parseIso8601("2023-01-01T00:00:00X").ok, "trailing offset")
    T.ok(not time.parseIso8601("not-a-date").ok, "garbage")
  end,

  ["day boundaries, weekday and duration"] = function(): void
    T.eq(time.startOfDayUtc(951782400 + 3600), 951782400, "start of day")
    T.eq(time.endOfDayUtc(951782400 + 3600), 951782400 + 86399, "end of day")
    T.eq(time.addDays(0, 1), 86400, "add day")
    T.eq(time.addSeconds(0, 90), 90, "add seconds")
    T.eq(time.weekday(0), 4, "Thursday")
    T.eq(time.isoWeekday(0), 4, "ISO Thursday")
    T.eq(time.weekday(1704067200), 1, "2024-01-01 Monday")
    T.eq(time.isoWeekday(1704067200), 1, "ISO Monday")
    T.eq(time.duration(0), "0s", "duration zero")
    T.eq(time.duration(3661), "1h 1m 1s", "duration")
    T.eq(time.duration(86400 + 3661), "1d 1h 1m 1s", "duration days")
    T.eq(time.duration(-3661), "-1h 1m 1s", "negative duration")
    T.eq(time.formatUtc(0, "%Y-%m-%d"), "1970-01-01", "format UTC")
  end,
}
