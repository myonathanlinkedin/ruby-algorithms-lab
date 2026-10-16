require 'minitest/autorun'
require_relative 'core'

class TestAVLTree < Minitest::Test
  def setup
    @tree = AVLTree.new
  end

  def test_insert_and_get
    @tree.insert(10, 'a')
    @tree.insert(20, 'b')
    @tree.insert(5, 'c')
    assert_equal 'a', @tree.get(10)
    assert_equal 'b', @tree.get(20)
    assert_equal 'c', @tree.get(5)
    assert_nil @tree.get(99)
  end

  def test_inorder_sorted
    keys = [30, 10, 20, 40, 35, 50]
    keys.each { |k| @tree.insert(k) }
    inorder_keys = @tree.inorder.map { |pair| pair[0] }
    assert_equal keys.sort, inorder_keys
  end

  def test_balancing_property
    (1..100).each { |i| @tree.insert(i) }
    assert @tree.balanced?
    assert_equal 100, @tree.size
  end

  def test_delete_leaf
    [15, 10, 20].each { |k| @tree.insert(k) }
    @tree.delete(10)
    assert_nil @tree.get(10)
    assert @tree.balanced?
  end

  def test_delete_node_with_one_child
    [30, 20, 10, 25].each { |k| @tree.insert(k) }
    @tree.delete(20)
    assert_nil @tree.get(20)
    assert @tree.balanced?
    assert_equal [10, 25, 30], @tree.inorder.map { |p| p[0] }
  end

  def test_delete_node_with_two_children
    [40, 20, 60, 10, 30, 50, 70].each { |k| @tree.insert(k) }
    @tree.delete(60)
    assert_nil @tree.get(60)
    assert @tree.balanced?
    expected = [10, 20, 30, 40, 50, 70]
    assert_equal expected, @tree.inorder.map { |p| p[0] }
  end

  def test_duplicate_key_updates_value
    @tree.insert(5, 'first')
    @tree.insert(5, 'second')
    assert_equal 1, @tree.size
    assert_equal 'second', @tree.get(5)
  end

  def test_empty_tree_operations
    assert_nil @tree.get(1)
    assert @tree.balanced?
    assert_equal [], @tree.inorder
    @tree.delete(1) # should be safe
    assert_equal 0, @tree.size
  end
end

if __FILE__ == $0
  puts "Manual sanity check..."
  tree = AVLTree.new
  [50, 30, 70, 20, 40, 60, 80].each { |k| tree.insert(k) }
  puts "Inorder: #{tree.inorder.map { |k, _| k }.inspect}"
  puts "Balanced? #{tree.balanced?}"
end
