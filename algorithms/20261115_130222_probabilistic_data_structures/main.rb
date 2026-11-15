# frozen_string_literal: true

require_relative 'engine'
require 'test/unit'

# Unit‑test suite for the BloomFilter implementation.
class TestBloomFilter < Test::Unit::TestCase
  def test_basic_add_and_query
    bf = BloomFilter.new(1000, 0.01)
    assert_false bf.include?('alice')
    bf.add('alice')
    assert_true bf.include?('alice')
    assert_false bf.include?('bob')
    bf.add('bob')
    assert_true bf.include?('bob')
  end

  def test_no_false_negatives_for_multiple_adds
    bf = BloomFilter.new(500, 0.05)
    items = %w[apple banana cherry date elderberry fig grape]
    items.each { |it| bf.add(it) }
    items.each { |it| assert_true bf.include?(it), "Expected #{it} to be present" }
  end

  def test_false_positive_rate_estimate
    expected_items = 2000
    fp_rate = 0.02
    bf = BloomFilter.new(expected_items, fp_rate)

    # Populate with distinct items.
    present = (1..expected_items).map { |i| "item#{i}" }
    present.each { |it| bf.add(it) }

    # Test a large set of unseen items.
    trials = 10_000
    false_positives = 0
    (1..trials).each do |i|
      candidate = "unknown#{i}"
      false_positives += 1 if bf.include?(candidate)
    end

    observed_fp = false_positives.to_f / trials
    # Allow a 30 % tolerance due to statistical variance.
    tolerance = 0.30 * fp_rate
    assert_in_delta fp_rate, observed_fp, tolerance, "Observed false positive rate #{observed_fp} deviates beyond tolerance"
  end

  def test_edge_cases
    bf = BloomFilter.new(10, 0.1)

    # Adding nil should raise because nil does not respond to #to_s in a useful way.
    assert_raise(ArgumentError) { bf.add(nil) }

    # Empty string is a valid element.
    assert_false bf.include?('')
    bf.add('')
    assert_true bf.include?('')

    # Adding the same element multiple times must not corrupt state.
    bf.add('repeat')
    bf.add('repeat')
    assert_true bf.include?('repeat')
  end

  def test_configuration_computation
    cfg = BloomFilterConfig.from_parameters(1000, 0.01)
    # Expected theoretical values (rounded up):
    #   m ≈ 9585 bits, k ≈ 7 hash functions.
    assert_equal 1000, cfg.expected_items
    assert_in_delta 0.01, cfg.false_positive_rate, 1e-9
    assert_equal 9585, cfg.bit_size
    assert_equal 7, cfg.hash_count
  end
end

# Demonstration block – runs when the file is executed directly.
if __FILE__ == $PROGRAM_NAME
  puts '--- Bloom Filter Demonstration ---'
  bf = BloomFilter.new(20, 0.05)
  %w[cat dog mouse].each { |animal| bf.add(animal) }

  %w[cat dog mouse elephant].each do |creature|
    puts "#{creature.inspect} => #{bf.include?(creature) ? 'possibly present' : 'definitely absent'}"
  end
end
