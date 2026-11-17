import T from "tlua_test"
import mathx from "../mathx"

return {
  ["clamp, sign and finite checks"] = function(): void
    T.eq(mathx.clamp(5, 0, 10), 5, "clamp middle")
    T.eq(mathx.clamp(-1, 0, 10), 0, "clamp low")
    T.eq(mathx.clamp(11, 0, 10), 10, "clamp high")
    T.eq(mathx.clamp01(0.25), 0.25, "clamp01")
    T.eq(mathx.clamp01(-1), 0, "clamp01 low")
    T.raises(function(): void mathx.clamp(1, 2, 1) end)
    T.eq(mathx.sign(-3), -1, "sign negative")
    T.eq(mathx.sign(0), 0, "sign zero")
    T.eq(mathx.sign(3), 1, "sign positive")
    T.ok(mathx.isFinite(1.5), "finite")
    T.ok(not mathx.isFinite(math.huge), "infinite")
    T.ok(not mathx.isFinite(0 / 0), "nan")
    T.ok(mathx.isInteger(2), "integer")
    T.ok(not mathx.isInteger(2.5), "not integer")
  end,

  ["gcd, lcm and primes"] = function(): void
    T.eq(mathx.gcd(12, 18), 6, "gcd")
    T.eq(mathx.gcd(-12, 18), 6, "negative gcd")
    T.eq(mathx.gcd(0, 5), 5, "gcd zero")
    T.eq(mathx.lcm(4, 6), 12, "lcm")
    T.eq(mathx.lcm(0, 6), 0, "lcm zero")
    T.ok(mathx.isPrime(2), "prime 2")
    T.ok(mathx.isPrime(3), "prime 3")
    T.ok(mathx.isPrime(97), "prime 97")
    T.ok(not mathx.isPrime(1), "one not prime")
    T.ok(not mathx.isPrime(0), "zero not prime")
    T.ok(not mathx.isPrime(100), "100 not prime")
    T.ok(not mathx.isPrime(-7), "negative not prime")
  end,

  ["factorial, fibonacci and rounding"] = function(): void
    T.eq(mathx.factorial(0), 1, "factorial 0")
    T.eq(mathx.factorial(5), 120, "factorial 5")
    T.raises(function(): void mathx.factorial(-1) end)
    T.raises(function(): void mathx.factorial(171) end)
    T.eq(mathx.fibonacci(0), 0, "fib 0")
    T.eq(mathx.fibonacci(1), 1, "fib 1")
    T.eq(mathx.fibonacci(10), 55, "fib 10")
    T.raises(function(): void mathx.fibonacci(-1) end)
    T.eq(mathx.round(1.2345, 3), 1.235, "round up")
    T.eq(mathx.round(1.2344, 3), 1.234, "round down")
    T.eq(mathx.round(-1.5, 0), -2, "round negative")
    T.raises(function(): void mathx.round(1, -1) end)
    T.raises(function(): void mathx.round(1, 16) end)
  end,

  ["approximation, interpolation and logs"] = function(): void
    T.ok(mathx.approxEqual(0.1 + 0.2, 0.3, 0.000001), "approx")
    T.ok(not mathx.approxEqual(1, 2, 0.1), "not approx")
    T.raises(function(): void mathx.approxEqual(1, 1, -1) end)
    T.eq(mathx.lerp(10, 20, 0.25), 12.5, "lerp")
    T.eq(mathx.inverseLerp(10, 20, 12.5), 0.25, "inverseLerp")
    T.raises(function(): void mathx.inverseLerp(1, 1, 2) end)
    T.eq(mathx.logBase(8, 2), 3, "log2")
    T.raises(function(): void mathx.logBase(0, 2) end)
    T.raises(function(): void mathx.logBase(8, 1) end)
    T.eq(mathx.hypot(3, 4), 5, "hypot")
    T.ok(mathx.isFinite(mathx.hypot(1e308, 1e308)), "hypot avoids overflow")
    T.eq(mathx.radians(180), math.pi, "radians")
    T.eq(mathx.degrees(math.pi), 180, "degrees")
  end,

  ["divMod, safeDivide and percent"] = function(): void
    local result = mathx.divMod(17, 5)
    T.eq(result.quotient, 3, "div quotient")
    T.eq(result.remainder, 2, "div remainder")
    local negative = mathx.divMod(-17, 5)
    T.eq(negative.quotient, -4, "negative quotient")
    T.eq(negative.remainder, 3, "negative remainder")
    T.raises(function(): void mathx.divMod(1, 0) end)
    T.eq(mathx.safeDivide(10, 2, -1), 5, "safeDivide")
    T.eq(mathx.safeDivide(10, 0, -1), -1, "safeDivide zero")
    T.eq(mathx.percent(25, 200), 12.5, "percent")
    T.raises(function(): void mathx.percent(1, 0) end)
  end,

  ["aggregates and median"] = function(): void
    T.eq(mathx.sum({ 1, 2, 3 }), 6, "sum")
    T.eq(mathx.mean({ 1, 2, 3, 4 }), 2.5, "mean")
    T.raises(function(): void mathx.mean({}) end)
    T.eq(mathx.median({ 3, 1, 2 }), 2, "median odd")
    T.eq(mathx.median({ 4, 1, 3, 2 }), 2.5, "median even")
    T.raises(function(): void mathx.median({}) end)
  end,
}
