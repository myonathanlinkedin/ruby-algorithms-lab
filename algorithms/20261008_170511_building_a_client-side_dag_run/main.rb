require_relative 'types'
require_relative 'engine'
require 'minitest/autorun'

class DAGTest < Minitest::Test
  def setup
    @dag = DAG.new
  end

  def test_empty_graph
    assert_equal [], @dag.topological_sort
    refute @dag.has_cycle?
  end

  def test_single_node
    @dag.add_node(:a)
    assert_equal [:a], @dag.topological_sort
    refute @dag.has_cycle?
  end

  def test_linear_chain
    @dag.add_node(:a).add_node(:b).add_node(:c)
    @dag.add_edge(:a, :b).add_edge(:b, :c)
    assert_equal [:a, :b, :c], @dag.topological_sort
  end

  def test_branching_structure
    @dag.add_node(:a).add_node(:b).add_node(:c).add_node(:d)
    @dag.add_edge(:a, :b)
    @dag.add_edge(:a, :c)
    @dag.add_edge(:b, :d)
    @dag.add_edge(:c, :d)

    order = @dag.topological_sort
    assert order.index(:a) < order.index(:b)
    assert order.index(:a) < order.index(:c)
    assert order.index(:b) < order.index(:d)
    assert order.index(:c) < order.index(:d)
  end

  def test_multiple_independent_components
    @dag.add_node(:a).add_node(:b).add_node(:c)
    @dag.add_node(:x).add_node(:y)

    @dag.add_edge(:a, :b)
    @dag.add_edge(:b, :c)
    @dag.add_edge(:x, :y)

    order = @dag.topological_sort
    assert order.index(:a) < order.index(:b)
    assert order.index(:b) < order.index(:c)
    assert order.index(:x) < order.index(:y)
    assert_includes order, :a
    assert_includes order, :x
  end

  def test_cycle_detection
    @dag.add_node(:a).add_node(:b).add_node(:c)
    @dag.add_edge(:a, :b)
    @dag.add_edge(:b, :c)
    @dag.add_edge(:c, :a)

    assert_raises(CycleError) { @dag.topological_sort }
    assert @dag.has_cycle?
  end

  def test_duplicate_node_error
    @dag.add_node(:a)
    assert_raises(ArgumentError) { @dag.add_node(:a) }
  end

  def test_self_loop_error
    @dag.add_node(:a)
    assert_raises(ArgumentError) { @dag.add_edge(:a, :a) }
  end

  def test_execute_runtime
    @dag.add_node(:a).add_node(:b).add_node(:c)
    @dag.add_edge(:a, :b)
    @dag.add_edge(:b, :c)

    visited = []
    @dag.execute { |node| visited << node.id }
    assert_equal [:a, :b, :c], visited
  end
end

# Demo execution when the file is run directly
if __FILE__ == $0
  puts "=== DAG Runtime Demo ==="
  demo = DAG.new
  %i[task1 task2 task3 task4].each { |t| demo.add_node(t) }
  demo.add_edge(:task1, :task2)
  demo.add_edge(:task1, :task3)
  demo.add_edge(:task2, :task4)
  demo.add_edge(:task3, :task4)

  puts "Topological order: #{demo.topological_sort.inspect}"
  puts "Executing tasks in order:"
  demo.execute { |node| puts "Running #{node.id}" }
end
