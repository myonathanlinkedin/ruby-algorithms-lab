require_relative 'core'
require 'minitest/autorun'

class TestAVLTree < Minitest::Test
  def setup
    @tree = AVLTree.new
  end

  def test_insert_and_find
    1.upto(10) { |i| @tree.insert(i, i * 10) }
    assert_equal 10, @tree.size
    (1..10).each { |i| assert_equal i * 10, @tree.find(i) }
  end

  def test_inorder_sorted
    keys = [50, 20, 70, 10, 30, 60, 80]
    keys.each { |k| @tree.insert(k, k) }
    inorder_keys = @tree.inorder.map { |kv| kv[0] }
    assert_equal keys.sort, inorder_keys
  end

  def test_duplicate_key_replaces_value
    @tree.insert(5, 'a')
    @tree.insert(5, 'b')
    assert_equal 1, @tree.size
    assert_equal 'b', @tree.find(5)
  end

  def test_delete_leaf
    [15, 10, 20].each { |k| @tree.insert(k, k) }
    @tree.delete(10)
    refute @tree.find(10)
    assert_equal [15, 20], @tree.inorder.map { |kv| kv[0] }
  end

  def test_delete_node_with_one_child
    [30, 20, 40, 10].each { |k| @tree.insert(k, k) }
    @tree.delete(20)
    assert_nil @tree.find(20)
    assert_equal [10, 30, 40], @tree.inorder.map { |kv| kv[0] }
  end

  def test_delete_node_with_two_children
    [50, 30, 70, 20, 40, 60, 80].each { |k| @tree.insert(k, k) }
    @tree.delete(30)
    assert_nil @tree.find(30)
    assert_equal [20, 40, 50, 60, 70, 80], @tree.inorder.map { |kv| kv[0] }
  end

  def test_aether_continuum
    [3, 1, 4, 2].each { |k| @tree.insert(k, k) }
    assert_equal [1, 2, 3, 4], @tree.aether_continuum
  end

  def test_merge
    t1 = AVLTree.new
    t2 = AVLTree.new
    [1, 3, 5].each { |k| t1.insert(k, k) }
    [2, 4, 6].each { |k| t2.insert(k, k) }
    t1.merge(t2)
    assert_equal 6, t1.size
    assert_equal (1..6).to_a, t1.aether_continuum
  end

  def test_balancing_property
    # Insert sequential keys to provoke imbalance if not rebalanced.
    1.upto(1000) { |i| @tree.insert(i, i) }
    # Height of AVL tree <= 1.44*log2(n+2) - 1 (tight bound)
    max_allowed = (1.44 * Math.log2(@tree.size + 2) - 1).ceil
    actual_height = @tree.send(:height, @tree.root)
    assert_operator actual_height, :<=, max_allowed
  end
end

if __FILE__ == $0
  # Entry point: run the test suite (Minitest does this automatically).
  # Additional simple benchmark (optional).
  require 'benchmark'

  tree = AVLTree.new
  n = 10_000
  puts "Benchmark: inserting #{n} random keys..."
  Benchmark.bm do |x|
    x.report { n.times { tree.insert(rand(1_000_000), nil) } }
  end
end
