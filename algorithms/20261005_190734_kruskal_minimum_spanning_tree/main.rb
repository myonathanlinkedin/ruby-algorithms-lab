# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'
require 'benchmark'

class TestKruskalMST < Minitest::Test
  def test_simple_triangle
    edges = [
      [0, 1, 1],
      [1, 2, 2],
      [0, 2, 3]
    ]
    kr = KruskalMST.new(3, edges)
    mst, weight = kr.compute
    assert_equal 2, mst.size
    assert_equal 3, weight
    assert_includes mst.map { |e| [e.u, e.v].sort }, [0, 1]
    assert_includes mst.map { |e| [e.u, e.v].sort }, [1, 2]
  end

  def test_multiple_equal_weights
    edges = [
      [0, 1, 1],
      [0, 2, 1],
      [1, 2, 1],
      [1, 3, 2],
      [2, 3, 2]
    ]
    kr = KruskalMST.new(4, edges)
    mst, weight = kr.compute
    assert_equal 3, mst.size
    assert_equal 4, weight
  end

  def test_disconnected_graph
    edges = [
      [0, 1, 1],
      [2, 3, 2]
    ]
    kr = KruskalMST.new(4, edges)
    assert_raises(RuntimeError) { kr.compute }
  end

  def test_large_random_graph
    n = 100
    rng = Random.new(42)
    edges = []
    (0...n).each do |i|
      ((i + 1)...n).each do |j|
        edges << [i, j, rng.rand(1..1000)]
      end
    end
    kr = KruskalMST.new(n, edges)
    mst, weight = kr.compute
    assert_equal n - 1, mst.size
    assert_kind_of Integer, weight
  end
end

if __FILE__ == $PROGRAM_NAME
  puts 'Running benchmark on 500-node complete graph...'
  n = 500
  edges = []
  (0...n).each do |i|
    ((i + 1)...n).each do |j|
      edges << [i, j, (i - j).abs + 1]
    end
  end
  kr = KruskalMST.new(n, edges)

  time = Benchmark.realtime { kr.compute }
  puts format('MST computed in %.4f seconds', time)
end
