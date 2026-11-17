--- Bounded queue, stack and binary priority queue.
---
--- The queue and priority queue have fixed capacities to make memory use
--- explicit; their `push`/`enqueue` methods return false when full rather than
--- growing without bound. `Stack` grows dynamically but remains a plain array.
--- All structures are generic; TypeLua requires an explicit type argument for
--- an empty constructor: `Queue.new<string>(8)`, `PriorityQueue.new<integer>(8, less)`.

class Queue<T> {
  items: map<integer, T> = {},
  head: integer = 1,
  tail: integer = 1,
  count: integer = 0,
  limit: integer,

  constructor(capacity: integer)
    if capacity < 1 then error("Queue capacity must be >= 1") end
    self.limit = capacity
  end,

  capacity(): integer
    return self.limit
  end,

  size(): integer
    return self.count
  end,

  isEmpty(): boolean
    return self.count == 0
  end,

  isFull(): boolean
    return self.count == self.limit
  end,

  enqueue(value: T): boolean
    if self.count >= self.limit then return false end
    self.items[self.tail] = value
    self.tail = self.tail + 1
    if self.tail > self.limit then self.tail = 1 end
    self.count = self.count + 1
    return true
  end,

  push(value: T): boolean
    return self:enqueue(value)
  end,

  dequeue(): T | nil
    if self.count == 0 then return nil end
    local value: T = self.items[self.head]!
    local raw: any = self.items
    raw[self.head] = nil
    self.head = self.head + 1
    if self.head > self.limit then self.head = 1 end
    self.count = self.count - 1
    return value
  end,

  pop(): T | nil
    return self:dequeue()
  end,

  peek(): T | nil
    if self.count == 0 then return nil end
    return self.items[self.head]
  end,

  clear(): void
    self.items = {}
    self.head = 1
    self.tail = 1
    self.count = 0
  end,

  toArray(): T[]
    local out: T[] = {}
    local index: integer = self.head
    for _: integer = 1, self.count do
      out[#out + 1] = self.items[index]!
      index = index + 1
      if index > self.limit then index = 1 end
    end
    return out
  end,
}

class Stack<T> {
  items: T[] = {},

  constructor() end,

  size(): integer
    return #self.items
  end,

  isEmpty(): boolean
    return #self.items == 0
  end,

  push(value: T): void
    self.items[#self.items + 1] = value
  end,

  pop(): T | nil
    if #self.items == 0 then return nil end
    local index: integer = #self.items
    local value: T = self.items[index]
    local raw: any = self.items
    raw[index] = nil
    return value
  end,

  peek(): T | nil
    if #self.items == 0 then return nil end
    return self.items[#self.items]
  end,

  clear(): void
    self.items = {}
  end,

  toArray(): T[]
    local out: T[] = {}
    for i: integer = 1, #self.items do out[i] = self.items[i] end
    return out
  end,
}

class PriorityQueue<T> {
  items: T[] = {},
  less: (a: T, b: T) -> boolean,
  limit: integer,

  constructor(capacity: integer, less: (a: T, b: T) -> boolean)
    if capacity < 1 then error("PriorityQueue capacity must be >= 1") end
    self.limit = capacity
    self.less = less
  end,

  capacity(): integer
    return self.limit
  end,

  size(): integer
    return #self.items
  end,

  isEmpty(): boolean
    return #self.items == 0
  end,

  isFull(): boolean
    return #self.items >= self.limit
  end,

  swap(first: integer, second: integer): void
    local temporary: T = self.items[first]
    self.items[first] = self.items[second]
    self.items[second] = temporary
  end,

  siftUp(index: integer): void
    while index > 1 do
      local parent: integer = math.floor(index / 2)
      if not self.less(self.items[index], self.items[parent]) then break end
      self:swap(index, parent)
      index = parent
    end
  end,

  siftDown(index: integer): void
    while true do
      local left: integer = index * 2
      local right: integer = left + 1
      local smallest: integer = index
      if left <= #self.items and self.less(self.items[left], self.items[smallest]) then
        smallest = left
      end
      if right <= #self.items and self.less(self.items[right], self.items[smallest]) then
        smallest = right
      end
      if smallest == index then return end
      self:swap(index, smallest)
      index = smallest
    end
  end,

  push(value: T): boolean
    if #self.items >= self.limit then return false end
    self.items[#self.items + 1] = value
    self:siftUp(#self.items)
    return true
  end,

  pop(): T | nil
    if #self.items == 0 then return nil end
    local top: T = self.items[1]
    local last: integer = #self.items
    self.items[1] = self.items[last]
    local raw: any = self.items
    raw[last] = nil
    if #self.items > 0 then self:siftDown(1) end
    return top
  end,

  peek(): T | nil
    if #self.items == 0 then return nil end
    return self.items[1]
  end,

  clear(): void
    self.items = {}
  end,

  --- Heap order, not sorted order.
  toArray(): T[]
    local out: T[] = {}
    for i: integer = 1, #self.items do out[i] = self.items[i] end
    return out
  end,
}

return {
  Queue = Queue,
  Stack = Stack,
  PriorityQueue = PriorityQueue,
}
