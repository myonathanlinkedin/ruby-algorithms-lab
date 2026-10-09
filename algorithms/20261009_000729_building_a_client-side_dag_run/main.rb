require 'test/unit'
require_relative 'engine'

class DAGTest < Test::Unit::TestCase
  def test_empty_graph
    dag = DAG.new
    assert_equal([], dag.topological_sort.map(&:id))
  end

  def test_single_node
    dag = DAG.new
    dag.add_node(:A)
    assert_equal([:A], dag.topological_sort.map(&:id))
  end

  def test_simple_dag
    dag = DAG.new
    %i[A B C].each { |id| dag.add_node(id) }
    dag.add_edge(:A, :B)
    dag.add_edge(:A, :C)
    dag.add_edge(:B, :C)

    order = dag.topological_sort.map(&:id)
    assert_equal([:A, :B, :C], order)
  end

  def test_multiple_components
    dag = DAG.new
    %i[A B C D].each { |id| dag.add_node(id) }
    dag.add_edge(:A, :B)
    dag.add_edge(:C, :D)

    order = dag.topological_sort.map(&:id)

    # Verify that each edge respects ordering
    assert(order.index(:A) < order.index(:B), 'A must precede B')
    assert(order.index(:C) < order.index(:D), 'C must precede D')
    # All nodes must be present
    assert_equal(4, order.uniq.size)
  end

  def test_cycle_detection
    dag = DAG.new
    %i[A B].each { |id| dag.add_node(id) }
    dag.add_edge(:A, :B)
    dag.add_edge(:B, :A)

    assert_raises(GraphError) { dag.topological_sort }
    assert_true(dag.has_cycle?)
  end

  def test_self_loop
    dag = DAG.new
    dag.add_node(:A)
    assert_raises(GraphError) { dag.add_edge(:A, :A) }
    assert_false(dag.has_cycle?)
  end

  def test_duplicate_edge
    dag = DAG.new
    %i[A B].each { |id| dag.add_node(id) }
    dag.add_edge(:A, :B)
    assert_raises(GraphError) { dag.add_edge(:A, :B) }
    assert_equal([:A, :B], dag.topological_sort.map(&:id))
  end

  def test_duplicate_node
    dag = DAG.new
    dag.add_node(:A)
    assert_raises(GraphError) { dag.add_node(:A) }
  end

  def test_complex_dag
    dag = DAG.new
    %i[5 7 3 11 8 2 9 10].each { |id| dag.add_node(id) }
    edges = [
      [5, 11], [7, 11], [7, 8], [3, 8],
      [3, 10], [11, 2], [11, 9], [8, 9]
    ]
    edges.each { |from, to| dag.add_edge(from, to) }

    order = dag.topological_sort.map(&:id)

    # Verify all precedence constraints
    edges.each do |from, to|
      assert(order.index(from) < order.index(to), "#{from} must precede #{to}")
    end
  end
end

# Demonstration (executed when the file is run directly)
if __FILE__ == $0
  puts "\n--- DAG Runtime Demonstration ---"
  demo = DAG.new
  %i[Task1 Task2 Task3 Task4].each { |t| demo.add_node(t) }
  demo.add_edge(:Task1, :Task2)
  demo.add_edge(:Task1, :Task3)
  demo.add_edge(:Task3, :Task4)

  puts "Topological order:"
  puts demo.topological_sort.map(&:id).join(' -> ')
end
