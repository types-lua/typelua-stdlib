--- Generic set backed by a Lua table.
---
--- Set membership uses Lua equality, so strings/numbers/booleans are value
--- keys and tables/functions/classes are reference keys. Iteration order is
--- unspecified. Mutating methods return whether the set changed where that is
--- meaningful; bulk operations return new sets and never mutate their inputs.
---
--- TypeLua needs an explicit type argument for an empty constructor:
--- `Set.new<string>()`.

class Set<T> {
  items: map<any, boolean> = {},

  constructor() end,

  add(value: T): boolean
    if self.items[value] == true then return false end
    self.items[value] = true
    return true
  end,

  remove(value: T): boolean
    if self.items[value] ~= true then return false end
    local raw: any = self.items
    raw[value] = nil
    return true
  end,

  has(value: T): boolean
    return self.items[value] == true
  end,

  contains(value: T): boolean
    return self:has(value)
  end,

  size(): integer
    local total: integer = 0
    for _ in pairs(self.items) do total = total + 1 end
    return total
  end,

  isEmpty(): boolean
    for _ in pairs(self.items) do return false end
    return true
  end,

  values(): T[]
    local out: T[] = {}
    for value, present in pairs(self.items) do
      if present then out[#out + 1] = value as T end
    end
    return out
  end,

  toArray(): T[]
    return self:values()
  end,

  clear(): void
    local raw: any = self.items
    local all: T[] = self:values()
    for i: integer = 1, #all do raw[all[i]] = nil end
  end,

  forEach(fn: (value: T) -> void): void
    for value, present in pairs(self.items) do
      if present then fn(value as T) end
    end
  end,

  union(other: Set<T>): Set<T>
    local out: Set<T> = Set.new<T>()
    local left: T[] = self:values()
    local right: T[] = other:values()
    for i: integer = 1, #left do out:add(left[i]) end
    for i: integer = 1, #right do out:add(right[i]) end
    return out
  end,

  intersection(other: Set<T>): Set<T>
    local out: Set<T> = Set.new<T>()
    local left: T[] = self:values()
    for i: integer = 1, #left do
      if other:has(left[i]) then out:add(left[i]) end
    end
    return out
  end,

  difference(other: Set<T>): Set<T>
    local out: Set<T> = Set.new<T>()
    local left: T[] = self:values()
    for i: integer = 1, #left do
      if not other:has(left[i]) then out:add(left[i]) end
    end
    return out
  end,

  isSubsetOf(other: Set<T>): boolean
    for value, present in pairs(self.items) do
      if present and not other:has(value as T) then return false end
    end
    return true
  end,

  equals(other: Set<T>): boolean
    if self:size() ~= other:size() then return false end
    return self:isSubsetOf(other)
  end,

  clone(): Set<T>
    local out: Set<T> = Set.new<T>()
    local all: T[] = self:values()
    for i: integer = 1, #all do out:add(all[i]) end
    return out
  end,
}

local function from<T>(values: T[]): Set<T>
  local out: Set<T> = Set.new<T>()
  for i: integer = 1, #values do out:add(values[i]) end
  return out
end

return {
  Set = Set,
  from = from,
}
