require_relative 'core'
require 'minitest/autorun'

class TestCowVector < Minitest::Test
  def setup
    @vec = CowVector.new([1, 2, 3])
  end

  def test_basic_operations
    assert_equal 3, @vec.size
    assert_equal 2, @vec[1]
    assert_equal [1, 2, 3], @vec.to_a

    @vec.push(4)
    assert_equal 4, @vec.size
    assert_equal 4, @vec[-1]

    popped = @vec.pop
    assert_equal 4, popped
    assert_equal 3, @vec.size
  end

  def test_index_bounds
    assert_raises(IndexError) { @vec[3] }
    assert_raises(IndexError) { @vec[-4] }
    assert_raises(TypeError)  { @vec['a'] }
  end

  def test_copy_on_write_sharing
    copy = @vec.dup
    # Both share the same buffer initially.
    assert_equal @vec.object_id, copy.object_id # objects differ, but internal buffer shared
    assert_equal @vec.to_a, copy.to_a

    # Mutate original – should trigger copy.
    @vec.push(99)
    refute_equal @vec.to_a, copy.to_a
    assert_equal [1, 2, 3, 99], @vec.to_a
    assert_equal [1, 2, 3], copy.to_a

    # Mutate copy – also triggers its own copy.
    copy[0] = 42
    assert_equal [42, 2, 3], copy.to_a
    assert_equal [1, 2, 3, 99], @vec.to_a
  end

  def test_multiple_shares_and_mutations
    a = @vec.dup
    b = @vec.dup
    c = a.dup

    # All three share the same underlying buffer.
    assert_equal @vec.to_a, a.to_a
    assert_equal @vec.to_a, b.to_a
    assert_equal @vec.to_a, c.to_a

    # Mutate b – only b should diverge.
    b.push(7)
    assert_equal [1, 2, 3, 7], b.to_a
    assert_equal [1, 2, 3], @vec.to_a
    assert_equal [1, 2, 3], a.to_a
    assert_equal [1, 2, 3], c.to_a

    # Mutate a – a diverges, c still shares original.
    a[1] = 88
    assert_equal [1, 88, 3], a.to_a
    assert_equal [1, 2, 3], @vec.to_a
    assert_equal [1, 2, 3], c.to_a
  end

  def test_equality_and_inspect
    other = CowVector.new([1, 2, 3])
    assert_equal @vec, other
    assert_equal "#<CowVector [1, 2, 3]>", @vec.inspect
  end

  def test_empty_and_pop_errors
    empty = CowVector.new
    assert empty.empty?
    assert_raises(IndexError) { empty.pop }
  end
end

# Simple benchmark (optional, not part of unit tests)
if __FILE__ == $0
  require 'benchmark'

  puts "Benchmark: Copy-on-Write vs. naive duplication"
  n = 1_000_0

  cow = CowVector.new
  naive = []

  cow_time = Benchmark.realtime do
    n.times { cow.push(rand) }
    dup_vec = cow.dup
    dup_vec[0] = -1   # forces copy
  end

  naive_time = Benchmark.realtime do
    n.times { naive << rand }
    dup_arr = naive.dup
    dup_arr[0] = -1
  end

  puts format("CowVector: %.4f s, Naive Array: %.4f s", cow_time, naive_time)
end
