# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'

class TestCowVector < Minitest::Test
  include CowVectorModule

  def test_basic_operations
    v = CowVector.new([1, 2, 3])
    assert_equal 3, v.size
    assert_equal 3, v.capacity
    assert_equal 2, v[1]
    v[1] = 20
    assert_equal 20, v[1]

    v.push(4)
    assert_equal 4, v.size
    assert_equal 4, v[3]

    popped = v.pop
    assert_equal 4, popped
    assert_equal 3, v.size
  end

  def test_negative_indexing
    v = CowVector.new(%w[a b c])
    assert_equal 'c', v[-1]
    v[-1] = 'z'
    assert_equal 'z', v[2]
    assert_nil v[3] # out of bounds returns nil like Array#[]
  end

  def test_copy_on_write_isolation
    original = CowVector.new([10, 20, 30])
    clone = original.clone

    # Both share the same buffer now; mutation should detach.
    original[0] = 99
    assert_equal 99, original[0]
    assert_equal 10, clone[0] # unchanged

    # Mutating clone should not affect original.
    clone.push(40)
    assert_equal 3, original.size
    assert_equal 4, clone.size
    assert_equal 40, clone[3]
  end

  def test_multiple_clones_and_refcount
    v1 = CowVector.new([1, 2])
    v2 = v1.clone
    v3 = v2.clone

    # All three share the same buffer (refcount == 3)
    v2.push(99) # triggers copy for v2 only
    assert_equal [1, 2], v1.to_a
    assert_equal [1, 2, 99], v2.to_a
    assert_equal [1, 2], v3.to_a
  end

  def test_capacity_growth
    v = CowVector.new
    assert_equal 0, v.size
    assert_equal 0, v.capacity

    5.times { |i| v << i }
    assert_equal 5, v.size
    assert_operator v.capacity, :>=, 5
    assert_equal (0..4).to_a, v.to_a
  end

  def test_pop_edge_cases
    v = CowVector.new([1])
    assert_equal 1, v.pop
    assert_equal 0, v.size
    assert_raises(IndexError) { v.pop }
  end

  def test_equality
    a = CowVector.new([1, 2, 3])
    b = CowVector.new([1, 2, 3])
    c = CowVector.new([1, 2])
    assert_equal a, b
    refute_equal a, c
    assert_equal a, [1, 2, 3]
  end

  def test_enumerable
    v = CowVector.new([5, 6, 7])
    collected = []
    v.each { |x| collected << x * 2 }
    assert_equal [10, 12, 14], collected
    assert_equal [5, 6, 7], v.map { |x| x }
  end
end

# Entry point for manual execution (outside test runner)
if __FILE__ == $PROGRAM_NAME
  include CowVectorModule
  vec = CowVector.new([:a, :b])
  puts "Initial: #{vec.to_a.inspect}"
  clone = vec.clone
  vec << :c
  puts "After push on original: #{vec.to_a.inspect}"
  puts "Clone unchanged: #{clone.to_a.inspect}"
end
