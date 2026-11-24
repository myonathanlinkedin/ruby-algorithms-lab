require 'minitest/autorun'
require_relative 'core'

class TestHopcroftKarp < Minitest::Test
  def test_empty_graph
    hk = HopcroftKarp.new(0, 0, [])
    assert_equal 0, hk.max_matching
  end

  def test_no_edges
    hk = HopcroftKarp.new(3, 3, [])
    assert_equal 0, hk.max_matching
  end

  def test_simple_one_edge
    hk = HopcroftKarp.new(1, 1, [[0, 0]])
    assert_equal 1, hk.max_matching
    assert_equal 0, hk.pair_u[0]
    assert_equal 0, hk.pair_v[0]
  end

  def test_multiple_disjoint_edges
    edges = [[0, 0], [1, 1], [2, 2]]
    hk = HopcroftKarp.new(3, 3, edges)
    assert_equal 3, hk.max_matching
  end

  def test_shared_right_vertex
    edges = [[0, 0], [1, 0]]
    hk = HopcroftKarp.new(2, 1, edges)
    assert_equal 1, hk.max_matching
  end

  def test_complete_bipartite
    n = 4
    edges = []
    n.times do |u|
      n.times { |v| edges << [u, v] }
    end
    hk = HopcroftKarp.new(n, n, edges)
    assert_equal n, hk.max_matching
  end

  def test_unbalanced_graph
    n_left = 5
    n_right = 3
    edges = [[0, 0], [0, 1], [1, 1], [2, 2], [3, 0], [4, 2]]
    hk = HopcroftKarp.new(n_left, n_right, edges)
    assert_equal 3, hk.max_matching
  end

  def test_random_small_graph
    rng = Random.new(42)
    20.times do
      n_left = rng.rand(1..6)
      n_right = rng.rand(1..6)
      edges = []
      n_left.times do |u|
        n_right.times do |v|
          edges << [u, v] if rng.rand < 0.3
        end
      end
      hk = HopcroftKarp.new(n_left, n_right, edges)
      size = hk.max_matching
      left_used = {}
      right_used = {}
      hk.pair_u.each_with_index do |v, u|
        next if v.nil?
        assert_nil left_used[u]
        assert_nil right_used[v]
        left_used[u] = true
        right_used[v] = true
      end
      assert_equal size, left_used.size
    end
  end
end

if __FILE__ == $0
  # Minitest autorun handles execution.
end
