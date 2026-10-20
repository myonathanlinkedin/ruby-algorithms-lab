require 'test/unit'
require_relative 'engine'

class HyperLogLogTest < Test::Unit::TestCase
  def test_initial_state
    hll = HyperLogLog.new(10) # 1024 registers
    assert_in_delta 0.0, hll.count, 0.1, "Empty HLL should estimate near zero"
  end

  def test_single_element
    hll = HyperLogLog.new
    hll.add('apple')
    assert_in_delta 1.0, hll.count, 0.5, "Single distinct element should estimate close to 1"
  end

  def test_distinct_elements_accuracy
    hll = HyperLogLog.new(12) # 4096 registers, ~1.6% error
    true_cardinality = 0
    1.upto(10_000) do |i|
      hll.add("item_#{i}")
      true_cardinality += 1
    end
    estimate = hll.count
    relative_error = (estimate - true_cardinality).abs / true_cardinality.to_f
    assert(relative_error < 0.05, "Relative error #{relative_error} exceeds 5% for 10k distinct items")
  end

  def test_duplicate_handling
    hll = HyperLogLog.new
    5.times { hll.add('duplicate') }
    assert_in_delta 1.0, hll.count, 0.5, "Duplicates must not inflate the estimate"
  end

  def test_merge_functionality
    h1 = HyperLogLog.new(11)
    h2 = HyperLogLog.new(11)

    1.upto(5_000) { |i| h1.add("a_#{i}") }
    3_001.upto(8_000) { |i| h2.add("b_#{i}") }

    merged = HyperLogLog.new(11).merge!(h1).merge!(h2)

    # True cardinality = 5_000 (a) + 5_000 (b) - overlap (2_000) = 8_000
    true_cardinality = 8_000
    estimate = merged.count
    relative_error = (estimate - true_cardinality).abs / true_cardinality.to_f
    assert(relative_error < 0.07, "Merged HLL relative error #{relative_error} exceeds 7%")
  end

  def test_precision_bounds
    assert_raise(ArgumentError) { HyperLogLog.new(3) }
    assert_nothing_raised { HyperLogLog.new(16) }
    assert_raise(ArgumentError) { HyperLogLog.new(17) }
  end
end

# Demonstration (executed when file is run directly)
if __FILE__ == $0
  puts "=== HyperLogLog Demonstration ==="
  hll = HyperLogLog.new(14) # ~1% standard error
  1.upto(100_000) { |i| hll.add("user_#{i}") }
  puts "True cardinality: 100_000"
  puts "Estimated cardinality: #{hll.count.round}"
  puts "Relative error: #{(((hll.count - 100_000).abs) / 100_000.0 * 100).round(2)} %"
end
