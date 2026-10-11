require 'minitest/autorun'
require_relative 'core'

class TestFibonacciHeap < Minitest::Test
  def setup
    @heap = FibonacciHeap.new
  end

  def test_insert_and_peek
    @heap.insert(5, :a)
    @heap.insert(3, :b)
    @heap.insert(7, :c)
    assert_equal 3, @heap.peek_min.key
    assert_equal :b, @heap.peek_min.value
  end

  def test_extract_min
    @heap.insert(10, :x)
    @heap.insert(2, :y)
    @heap.insert(4, :z)
    min = @heap.extract_min
    assert_equal 2, min.key
    assert_equal :y, min.value
    assert_equal 2, @heap.size
    assert_equal 4, @heap.peek_min.key
  end

  def test_decrease_key
    n1 = @heap.insert(20, :a)
    n2 = @heap.insert(15, :b)
    n3 = @heap.insert(30, :c)
    @heap.decrease_key(n3, 5)
    assert_equal 5, @heap.peek_min.key
    assert_equal :c, @heap.peek_min.value
    # Decrease to a value larger than current should raise.
    assert_raises(ArgumentError) { @heap.decrease_key(n2, 25) }
  end
end

class TestDijkstra < Minitest::Test
  def setup
    @g = Graph.new
    # Graph:
    # A --1--> B --2--> C
    # A --4--> C
    # B --1--> D
    # C --3--> D
    @g.add_edge(:A, :B, 1)
    @g.add_edge(:B, :C, 2)
    @g.add_edge(:A, :C, 4)
    @g.add_edge(:B, :D, 1)
    @g.add_edge(:C, :D, 3)
  end

  def test_shortest_paths
    dist, prev = @g.dijkstra(:A)
    expected = { A: 0, B: 1, C: 3, D: 2 }
    assert_equal expected, dist.transform_keys { |k| k }
    # Verify predecessor chain for D is B -> A
    assert_equal :B, prev[:D]
    assert_equal :A, prev[:B]
    assert_nil prev[:A]
  end

  def test_unreachable_vertex
    @g.add_edge(:E, :F, 1) # disconnected component
    dist, prev = @g.dijkstra(:A)
    assert_equal Float::INFINITY, dist[:E]
    assert_nil prev[:E]
  end

  def test_negative_weight_rejection
    assert_raises(ArgumentError) { @g.add_edge(:X, :Y, -5) }
  end
end

# Simple benchmark (optional, not part of unit tests)
if __FILE__ == $0
  require 'benchmark'

  g = Graph.new
  1000.times do |i|
    g.add_edge(i, i + 1, 1)
    g.add_edge(i, i + 2, 2) if i + 2 <= 1000
  end

  puts Benchmark.measure { g.dijkstra(0) }
end

# === END OF main.rb ===
