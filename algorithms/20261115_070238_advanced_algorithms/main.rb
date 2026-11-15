# frozen_string_literal: true

require_relative 'core'
require 'test/unit'
require 'benchmark'

class TestFibonacciHeap < Test::Unit::TestCase
  def test_basic_operations
    heap = FibonacciHeap.new
    assert_true heap.empty?

    n1 = heap.insert(5, 'a')
    assert_false heap.empty?
    assert_equal 5, heap.find_min.key

    n2 = heap.insert(3, 'b')
    assert_equal 3, heap.find_min.key

    n3 = heap.insert(7, 'c')
    assert_equal 3, heap.find_min.key

    min = heap.extract_min
    assert_equal 3, min.key
    assert_equal 'b', min.value
    assert_equal 5, heap.find_min.key

    heap.decrease_key(n3, 2)
    assert_equal 2, heap.find_min.key
    assert_equal 'c', heap.find_min.value
  end

  def test_decrease_key_error
    heap = FibonacciHeap.new
    n = heap.insert(10, 'x')
    assert_raise(ArgumentError) { heap.decrease_key(n, 15) }
  end
end

class TestGraphDijkstra < Test::Unit::TestCase
  def setup
    @g = Graph.new
    # Example graph from CLRS (Figure 24.2)
    @g.add_edge('s', 't', 10)
    @g.add_edge('s', 'y', 5)
    @g.add_edge('t', 'x', 1)
    @g.add_edge('t', 'y', 2)
    @g.add_edge('y', 't', 3)
    @g.add_edge('y', 'x', 9)
    @g.add_edge('y', 'z', 2)
    @g.add_edge('x', 'z', 4)
    @g.add_edge('z', 's', 7)
    @g.add_edge('z', 'x', 6)
  end

  def test_shortest_paths
    dist, prev = @g.dijkstra('s')
    expected = {
      's' => 0,
      't' => 8,
      'x' => 9,
      'y' => 5,
      'z' => 7
    }
    expected.each do |v, d|
      assert_in_delta d, dist[v], 1e-9, "Distance to #{v}"
    end

    # Verify predecessor chain for 'x' (s -> y -> t -> x)
    assert_equal 't', prev['x']
    assert_equal 'y', prev['t']
    assert_equal 's', prev['y']
  end

  def test_unreachable_vertex
    @g.add_vertex('isolated')
    dist, _ = @g.dijkstra('s')
    assert_equal Float::INFINITY, dist['isolated']
  end

  def test_negative_weight_error
    assert_raise(ArgumentError) { @g.add_edge('a', 'b', -1) }
  end

  def test_source_not_in_graph
    assert_raise(ArgumentError) { @g.dijkstra('nonexistent') }
  end
end

# Simple benchmark comparing Fibonacci heap Dijkstra vs naive array implementation.
class BenchmarkDijkstra < Test::Unit::TestCase
  def test_benchmark
    g = Graph.new
    vertices = (0...1000).to_a.map { |i| "v#{i}" }
    vertices.each { |v| g.add_vertex(v) }
    # Create a sparse random graph
    rng = Random.new(42)
    5000.times do
      u = vertices[rng.rand(vertices.size)]
      v = vertices[rng.rand(vertices.size)]
      next if u == v

      w = rng.rand(1..10)
      g.add_edge(u, v, w)
    end

    puts 'Benchmarking Dijkstra with Fibonacci heap on 1000 vertices, 5000 edges:'
    time = Benchmark.realtime { g.dijkstra(vertices.first) }
    puts format('Elapsed time: %.6f seconds', time)
    # No assertion; just ensure it runs within reasonable time (<5 seconds on typical hardware)
    assert_true time < 5.0
  end
end

if __FILE__ == $PROGRAM_NAME
  # Run the test suite when executed directly.
  Test::Unit::AutoRunner.run
end
