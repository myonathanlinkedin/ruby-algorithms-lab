require_relative 'core'
require 'test/unit'

class TestHyperLogLog < Test::Unit::TestCase
  def test_empty_estimate
    h = HyperLogLog.new(10)
    assert_equal(0, h.count.round)
  end

  def test_small_cardinality
    h = HyperLogLog.new(10)
    100.times { |i| h.add(i) }
    est = h.count
    assert_in_delta(100, est, 5) # 5% tolerance
  end

  def test_medium_cardinality
    h = HyperLogLog.new(12)
    n = 10_000
    n.times { |i| h.add(i) }
    est = h.count
    assert_in_delta(n, est, n * 0.05) # 5% tolerance
  end

  def test_large_cardinality
    h = HyperLogLog.new(14)
    n = 200_000
    n.times { |i| h.add(i) }
    est = h.count
    assert_in_delta(n, est, n * 0.05)
  end

  def test_merge_disjoint_sets
    h1 = HyperLogLog.new(10)
    h2 = HyperLogLog.new(10)
    0.upto(49) { |i| h1.add(i) }
    50.upto(99) { |i| h2.add(i) }
    h1.merge!(h2)
    est = h1.count
    assert_in_delta(100, est, 5)
  end

  def test_merge_precision_mismatch
    h1 = HyperLogLog.new(10)
    h2 = HyperLogLog.new(12)
    assert_raise(ArgumentError) { h1.merge!(h2) }
  end

  def test_repeat_elements
    h = HyperLogLog.new(10)
    1_000.times { h.add('duplicate') }
    est = h.count
    assert_in_delta(1, est, 0.5) # should be close to 1
  end
end

# Demonstration when run directly (outside test runner)
if __FILE__ == $0 && !defined?(Test::Unit::AutoRunner)
  puts "Demo: estimating distinct integers 0..9999"
  h = HyperLogLog.new(12)
  10_000.times { |i| h.add(i) }
  puts "Estimated cardinality: #{h.count.round}"
end
