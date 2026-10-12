require 'minitest/autorun'
require_relative 'core'

# Unit‑test suite for Graph and BFS implementation.
class TestGraphBFS < Minitest::Test
  def test_empty_graph
    g = Graph.new
    assert_raises(ArgumentError) { g.bfs(:any) }
  end

  def test_single_vertex
    g = Graph.new
    g.add_vertex(:a)
    assert_equal [:a], g.bfs(:a)
  end

  def test_undirected_simple
    g = Graph.new
    g.add_edge(:a, :b).add_edge(:a, :c).add_edge(:b, :d)
    assert_equal [:a, :b, :c, :d], g.bfs(:a)
  end

  def test_directed_cycle
    g = Graph.new(directed: true)
    g.add_edge(:a, :b).add_edge(:b, :c).add_edge(:c, :a)
    assert_equal [:a, :b, :c], g.bfs(:a)
  end

  def test_disconnected_components
    g = Graph.new
    g.add_edge(1, 2).add_edge(2, 3)   # component A
    g.add_edge(10, 11)                # component B
    assert_equal [1, 2, 3], g.bfs(1)
    assert_equal [10, 11], g.bfs(10)
  end

  def test_self_loop
    g = Graph.new
    g.add_edge(:x, :x)
    assert_equal [:x], g.bfs(:x)
  end

  def test_multiple_paths
    g = Graph.new
    g.add_edge(:s, :a).add_edge(:s, :b)
    g.add_edge(:a, :c).add_edge(:b, :c)
    # BFS should visit :s, then :a and :b (order of insertion), then :c.
    assert_equal [:s, :a, :b, :c], g.bfs(:s)
  end

  def test_start_not_present
    g = Graph.new
    g.add_edge(:a, :b)
    assert_raises(ArgumentError) { g.bfs(:z) }
  end

  def test_visited_marked_on_enqueue
    # Construct a graph where premature marking would cause missing nodes.
    g = Graph.new
    g.add_edge(1, 2).add_edge(2, 3).add_edge(3, 4)
    # Correct BFS order: 1,2,3,4
    assert_equal [1, 2, 3, 4], g.bfs(1)
  end
end

# Simple benchmark demonstrating linear time behavior.
if __FILE__ == $0
  require 'benchmark'

  # Build a linear chain of 10_000 vertices.
  size = 10_000
  g = Graph.new
  (0...size).each { |i| g.add_edge(i, i + 1) }

  puts "Running BFS on a chain of #{size + 1} vertices..."
  Benchmark.bm do |bm|
    bm.report(:bfs) { g.bfs(0) }
  end
end
