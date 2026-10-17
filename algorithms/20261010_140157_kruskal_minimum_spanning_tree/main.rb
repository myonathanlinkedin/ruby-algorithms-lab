# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'

# Helper to build edges from an adjacency matrix (for testing convenience).
def edges_from_matrix(matrix)
  edges = []
  n = matrix.size
  (0...n).each do |i|
    (i + 1...n).each do |j|
      w = matrix[i][j]
      next if w.nil?
      edges << Edge.new(i, j, w)
    end
  end
  edges
end

class TestKruskalMST < Minitest::Test
  def test_triangle_graph
    #   0
    #  / \
    # 1---2
    # weights: 0-1=1, 0-2=3, 1-2=2
    edges = [
      Edge.new(0, 1, 1),
      Edge.new(0, 2, 3),
      Edge.new(1, 2, 2)
    ]
    mst = Kruskal.minimum_spanning_tree(edges, 3)
    assert_equal 2, mst.size
    total_weight = mst.map(&:weight).sum
    assert_equal 3, total_weight
    # Expected edges: (0-1) and (1-2)
    assert_includes mst, edges[0]
    assert_includes mst, edges[2]
  end

  def test_square_with_diagonal
    # 0---1
    # | \ |
    # 3---2
    # edges with weights:
    # 0-1=1, 1-2=1, 2-3=1, 3-0=1, 0-2=2 (diagonal)
    edges = [
      Edge.new(0, 1, 1),
      Edge.new(1, 2, 1),
      Edge.new(2, 3, 1),
      Edge.new(3, 0, 1),
      Edge.new(0, 2, 2)
    ]
    mst = Kruskal.minimum_spanning_tree(edges, 4)
    assert_equal 3, mst.size
    total_weight = mst.map(&:weight).sum
    assert_equal 3, total_weight
    # Diagonal must be excluded.
    refute_includes mst, edges[4]
  end

  def test_negative_weights
    edges = [
      Edge.new(0, 1, -5),
      Edge.new(1, 2, -2),
      Edge.new(0, 2, 4)
    ]
    mst = Kruskal.minimum_spanning_tree(edges, 3)
    assert_equal 2, mst.size
    total_weight = mst.map(&:weight).sum
    assert_equal -7, total_weight
  end

  def test_self_loops_and_parallel_edges
    edges = [
      Edge.new(0, 0, 10), # self‑loop, should be ignored
      Edge.new(0, 1, 5),
      Edge.new(0, 1, 3),  # parallel edge, lighter one should be chosen
      Edge.new(1, 2, 2)
    ]
    mst = Kruskal.minimum_spanning_tree(edges, 3)
    assert_equal 2, mst.size
    total_weight = mst.map(&:weight).sum
    assert_equal 5, total_weight # 3 + 2
    assert_includes mst, edges[2]
    assert_includes mst, edges[3]
  end

  def test_disconnected_graph_raises
    edges = [
      Edge.new(0, 1, 1),
      Edge.new(2, 3, 1)
    ]
    assert_raises(ArgumentError) { Kruskal.minimum_spanning_tree(edges, 4) }
  end

  def test_large_random_graph_consistency
    n = 50
    rng = Random.new(42)
    edges = []
    n.times do |i|
      (i + 1...n).each do |j|
        # 30% chance of having an edge
        if rng.rand < 0.3
          weight = rng.rand(-10..20)
          edges << Edge.new(i, j, weight)
        end
      end
    end

    # Ensure the graph is connected; if not, add a spanning chain.
    (0...n - 1).each { |i| edges << Edge.new(i, i + 1, 0) } unless edges.size.zero?

    mst = Kruskal.minimum_spanning_tree(edges, n)
    assert_equal n - 1, mst.size
    # Verify no cycles: UnionFind after MST should have single component.
    uf = UnionFind.new(n)
    mst.each { |e| uf.union(e.u, e.v) }
    root = uf.find(0)
    n.times { |i| assert_equal root, uf.find(i) }
  end
end

# Simple benchmark when the file is executed directly.
if __FILE__ == $PROGRAM_NAME
  require 'benchmark'

  puts "\nBenchmark: Kruskal on a dense graph (200 vertices, ~20k edges)"
  n = 200
  edges = []
  (0...n).each do |i|
    ((i + 1)...n).each do |j|
      edges << Edge.new(i, j, rand(1..1000))
    end
  end

  time = Benchmark.realtime do
    Kruskal.minimum_spanning_tree(edges, n)
  end
  puts "Elapsed time: #{format('%.6f', time)} seconds"
end
