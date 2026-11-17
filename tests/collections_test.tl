import T from "tlua_test"
import collections from "../collections"

return {
  ["bounded FIFO queue"] = function(): void
    local q = collections.Queue.new<string>(3)
    T.raises(function(): void collections.Queue.new<string>(0) end)
    T.ok(q:isEmpty(), "empty")
    T.ok(q:enqueue("a"), "enqueue a")
    T.ok(q:enqueue("b"), "enqueue b")
    T.ok(q:enqueue("c"), "enqueue c")
    T.ok(not q:enqueue("d"), "full")
    T.eq(q:size(), 3, "size")
    T.eq(q:peek(), "a", "peek")
    T.eq(q:dequeue(), "a", "dequeue a")
    T.eq(q:dequeue(), "b", "dequeue b")
    T.ok(q:enqueue("d"), "wrap enqueue")
    T.eq(table.concat(q:toArray(), ","), "c,d", "wrapped toArray")
    T.eq(q:dequeue(), "c", "dequeue c")
    T.eq(q:dequeue(), "d", "dequeue d")
    T.eq(q:dequeue(), nil, "empty dequeue")
    T.ok(q:isEmpty(), "empty again")
    q:clear()
    T.eq(q:size(), 0, "clear")
  end,

  ["stack is LIFO"] = function(): void
    local s = collections.Stack.new<integer>()
    T.ok(s:isEmpty(), "empty")
    s:push(1)
    s:push(2)
    s:push(3)
    T.eq(s:size(), 3, "size")
    T.eq(s:peek(), 3, "peek")
    T.eq(s:pop(), 3, "pop 3")
    T.eq(s:pop(), 2, "pop 2")
    T.eq(s:pop(), 1, "pop 1")
    T.eq(s:pop(), nil, "empty pop")
    s:push(9)
    T.eq(s:toArray()[1], 9, "toArray")
    s:clear()
    T.ok(s:isEmpty(), "clear")
  end,

  ["priority queue is a min-heap and bounded"] = function(): void
    T.raises(function(): void
      collections.PriorityQueue.new<integer>(0, function(a: integer, b: integer): boolean
        return a < b
      end)
    end)
    local pq = collections.PriorityQueue.new<integer>(4, function(a: integer, b: integer): boolean
      return a < b
    end)
    T.ok(pq:push(5), "push 5")
    T.ok(pq:push(1), "push 1")
    T.ok(pq:push(3), "push 3")
    T.ok(pq:push(2), "push 2")
    T.ok(not pq:push(0), "full")
    T.eq(pq:size(), 4, "size")
    T.eq(pq:peek(), 1, "peek")
    T.eq(pq:pop(), 1, "pop 1")
    T.eq(pq:pop(), 2, "pop 2")
    T.eq(pq:pop(), 3, "pop 3")
    T.eq(pq:pop(), 5, "pop 5")
    T.eq(pq:pop(), nil, "empty")
    pq:push(10)
    T.eq(pq:toArray()[1], 10, "toArray")
    local maxHeap = collections.PriorityQueue.new<integer>(3, function(a: integer, b: integer): boolean
      return a > b
    end)
    maxHeap:push(1)
    maxHeap:push(9)
    maxHeap:push(5)
    T.eq(maxHeap:pop(), 9, "max heap")
    pq:clear()
    T.ok(pq:isEmpty(), "clear")
  end,
}
