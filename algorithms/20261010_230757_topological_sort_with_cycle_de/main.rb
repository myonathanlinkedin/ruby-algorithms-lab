# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'core'

# Unit tests for DirectedGraph#topological_sort and cycle detection.
class TopologicalSortTest < Minitest::Test
  def test_empty_graph
    g = DirectedGraph.new
    assert_equal [], g.topological_sort
  end

  def test_single_vertex
    g = DirectedGraph.new
    g.add_vertex(:a)
    assert_equal [:a], g.topological_sort
  end

  def test_simple_acyclic
    g = DirectedGraph.new
    g.add_edge(:a, :b).add_edge(:b, :c)
    order = g.topological_sort
    assert_valid_order(order, g)
    # Expected order is [:a, :b, :c] but any topological order is acceptable
    assert_includes order, :a
    assert_includes order, :b
    assert_includes order, :c
  end

  def test_multiple_components
    g = DirectedGraph.new
    g.add_edge(1, 2)
    g.add_edge(3, 4)
    g.add_vertex(5) # isolated vertex
    order = g.topological_sort
    assert_valid_order(order, g)
    # Ensure all vertices appear
    assert_equal [1, 2, 3, 4, 5].sort, order.sort
  end

  def test_cycle_detection
    g = DirectedGraph.new
    g.add_edge(:x, :y).add_edge(:y, :z).add_edge(:z, :x)
    assert_raises(DirectedGraph::CycleError) { g.topological_sort }
  end

  def test_self_loop
    g = DirectedGraph.new
    g.add_edge(:self, :self)
    assert_raises(DirectedGraph::CycleError) { g.topological_sort }
  end

  def test_complex_acyclic
    g = DirectedGraph.new
    edges = [
      [:a, :d], [:f, :b], [:b, :d], [:f, :a],
      [:d, :c], [:c, :e], [:e, :g]
    ]
    edges.each { |u, v| g.add_edge(u, v) }
    order = g.topological_sort
    assert_valid_order(order, g)
    # Verify a specific precedence constraint
    assert order.index(:f) < order.index(:a)
    assert order.index(:a) < order.index(:d)
    assert order.index(:d) < order.index(:c)
    assert order.index(:c) < order.index(:e)
    assert order.index(:e) < order.index(:g)
  end

  private

  # Helper that asserts every edge respects the topological ordering.
  def assert_valid_order(order, graph)
    position = {}
    order.each_with_index { |v, i| position[v] = i }
    graph.instance_variable_get(:@adj).each do |src, dests|
      dests.each do |dst|
        assert position[src] < position[dst],
               "Vertex #{src} should appear before #{dst}"
      end
    end
  end
end

# Demonstration block: runs when the file is executed directly.
if __FILE__ == $PROGRAM_NAME
  puts '--- Topological Sort Demo ---'
  demo = DirectedGraph.new
  demo.add_edge('install', 'configure')
      .add_edge('configure', 'run')
      .add_edge('install', 'run')
  puts "Graph vertices: #{demo.vertices.inspect}"
  puts "Topological order: #{demo.topological_sort.inspect}"
end
