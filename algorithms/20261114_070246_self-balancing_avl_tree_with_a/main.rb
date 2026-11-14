require_relative 'core'
require 'minitest/autorun'

class TestAVLTree < Minitest::Test
  def setup
    @tree = AVLTree.new
    @keys = [30, 20, 40, 10, 25, 22, 35, 50, 5, 15]
    @keys.each { |k| @tree.insert(k) }
  end

  def test_inorder_sorted
    assert_equal @keys.sort, @tree.inorder
  end

  def test_balance_factors_within_one
    assert balanced?(@tree.root)
  end

  def test_find_existing_and_missing
    node = @tree.find(25)
    refute_nil node
    assert_equal 25, node.key

    assert_nil @tree.find(999)
  end

  def test_deletion_leaf
    @tree.delete(5)
    refute @tree.find(5)
    assert balanced?(@tree.root)
    assert_equal (@keys - [5]).sort, @tree.inorder
  end

  def test_deletion_one_child
    @tree.delete(10) # 10 has right child 15 after previous insertions
    refute @tree.find(10)
    assert balanced?(@tree.root)
  end

  def test_deletion_two_children
    @tree.delete(20)
    refute @tree.find(20)
    assert balanced?(@tree.root)
  end

  def test_graph_edges_count
    edges = @tree.graph_edges
    # For n nodes, a tree has n-1 edges
    assert_equal @tree.inorder.size - 1, edges.size
    # Ensure every edge connects existing keys
    keys = @tree.inorder
    edges.each do |parent, child|
      assert_includes keys, parent
      assert_includes keys, child
    end
  end

  private

  # Recursively verify balance factor constraint
  def balanced?(node)
    return true unless node
    bf = height(node.left) - height(node.right)
    return false if bf.abs > 1
    balanced?(node.left) && balanced?(node.right)
  end

  def height(node)
    node ? node.height : 0
  end
end

# Entry point for manual execution
if __FILE__ == $0
  tree = AVLTree.new
  [3, 2, 1, 4, 5, 6, 7, 16, 15, 14, 13, 12, 11, 10, 8, 9].each { |k| tree.insert(k) }
  puts "Inorder traversal: #{tree.inorder.inspect}"
  puts "Graph edges: #{tree.graph_edges.inspect}"
end
