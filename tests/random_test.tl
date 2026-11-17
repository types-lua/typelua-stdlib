import T from "tlua_test"
import random from "../random"

return {
  ["deterministic sequence and floats"] = function(): void
    local rng = random.Random.new(1)
    T.eq(rng:nextUint(), 270369, "first")
    T.eq(rng:nextUint(), 67634689, "second")
    T.eq(rng:nextUint(), 2647435461, "third")
    T.eq(rng:nextUint(), 307599695, "fourth")
    local first = random.Random.new(12345)
    local second = random.Random.new(12345)
    for _: integer = 1, 20 do
      T.eq(first:nextUint(), second:nextUint(), "same seed")
    end
    local different = random.Random.new(54321)
    T.ok(different:nextUint() ~= first:nextUint(), "different seed")
    local default = random.Random.new(0)
    T.eq(default:nextUint(), 723471715, "zero seeds to default")
    for _: integer = 1, 100 do
      local value: number = first:nextFloat()
      T.ok(value >= 0 and value < 1, "float range")
    end
  end,

  ["nextInt, bool and bytes"] = function(): void
    local rng = random.Random.new(77)
    for _: integer = 1, 1000 do
      local value: integer = rng:nextInt(-3, 7)
      T.ok(value >= -3 and value <= 7, "int range")
    end
    T.eq(rng:nextInt(5, 5), 5, "single value")
    T.raises(function(): void rng:nextInt(2, 1) end)
    T.raises(function(): void rng:nextInt(-3000000000, 3000000000) end)
    T.ok(rng:bool(0) == false, "zero probability")
    T.ok(rng:bool(1) == true, "one probability")
    T.raises(function(): void rng:bool(-0.1) end)
    T.raises(function(): void rng:bool(1.1) end)
    T.eq(#rng:nextBytes(16), 16, "bytes length")
    T.eq(#rng:nextBytes(0), 0, "empty bytes")
    T.raises(function(): void rng:nextBytes(-1) end)
  end,

  ["choice, shuffle and sample"] = function(): void
    local rng = random.Random.new(99)
    local items: integer[] = { 1, 2, 3, 4, 5 }
    local chosen: integer = random.choice<integer>(rng, items)
    T.ok(chosen >= 1 and chosen <= 5, "choice range")
    T.raises(function(): void random.choice<integer>(rng, {}) end)
    local shuffled: integer[] = random.shuffle<integer>(rng, items)
    T.eq(#shuffled, #items, "shuffle length")
    local seen: map<integer, boolean> = {}
    for i: integer = 1, #shuffled do
      T.ok(not seen[shuffled[i]], "shuffle unique")
      seen[shuffled[i]] = true
    end
    T.eq(items[1], 1, "shuffle input untouched")
    local picked: integer[] = random.sample<integer>(rng, items, 3)
    T.eq(#picked, 3, "sample count")
    local pickedSeen: map<integer, boolean> = {}
    for i: integer = 1, #picked do
      T.ok(not pickedSeen[picked[i]], "sample unique")
      pickedSeen[picked[i]] = true
    end
    T.eq(#random.sample<integer>(rng, items, 0), 0, "sample zero")
    T.eq(#random.sample<integer>(rng, items, 5), 5, "sample all")
    T.raises(function(): void random.sample<integer>(rng, items, 6) end)
    T.raises(function(): void random.sample<integer>(rng, items, -1) end)
  end,
}
