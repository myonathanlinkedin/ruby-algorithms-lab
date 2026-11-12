require_relative 'core'
require 'minitest/autorun'

class TestDiagramGraph < Minitest::Test
  def setup
    @g = Diagram::Graph.new
    @g.add_node(:A, 'Alpha')
    @g.add_node(:B, 'Beta')
    @g.add_node(:C, 'Gamma')
    @g.add_edge(:A, :B, 'a→b')
    @g.add_edge(:B, :C)
  end

  def test_node_addition
    assert_equal 3, @g.nodes.size
    assert @g.nodes.key?('A')
    assert_equal 'Alpha', @g.nodes['A'].label
  end

  def test_edge_addition
    assert_equal 2, @g.edges.size
    e = @g.edges.find { |ed| ed.src == 'A' && ed.dst == 'B' }
    refute_nil e
    assert_equal 'a→b', e.label
  end

  def test_grid_layout_dimensions
    layout = @g.grid_layout
    cols = layout.values.map { |_, c| c }.max + 1
    rows = layout.values.map { |r, _| r }.max + 1
    assert_equal 2, cols   # sqrt(3) => 2 columns
    assert_equal 2, rows   # 3 nodes fit in 2 rows
  end

  def test_html_contains_nodes_and_edges
    html = @g.to_html
    assert_match /id="node-A"/, html
    assert_match /Alpha/, html
    assert_match /class="edge"/, html
    assert_match /a→b/, html
  end

  def test_duplicate_node_raises
    assert_raises(ArgumentError) { @g.add_node(:A) }
  end

  def test_missing_node_edge_raises
    assert_raises(ArgumentError) { @g.add_edge(:X, :A) }
    assert_raises(ArgumentError) { @g.add_edge(:A, :Y) }
  end
end

# Demonstration when executed directly.
if __FILE__ == $0
  sample = Diagram::Graph.new
  sample.add_node(:Home, 'Home')
  sample.add_node(:About, 'About')
  sample.add_node(:Contact, 'Contact')
  sample.add_node(:Blog, 'Blog')
  sample.add_edge(:Home, :About)
  sample.add_edge(:Home, :Contact)
  sample.add_edge(:About, :Blog, 'reads')
  puts sample.to_html
end
