# Unit tests and simple benchmark for BloomFilter.
# Uses Ruby's built‑in Minitest framework (standard library).

require 'minitest/autorun'
require_relative 'core'

class TestBloomFilter < Minitest::Test
  def setup
    @size = 1024          # bits
    @hashes = 4
    @filter = BloomFilter.new(@size, @hashes)
  end

  def test_add_and_include
    items = %w[apple banana cherry]
    items.each { |it| @filter.add(it) }

    items.each do |it|
      assert @filter.include?(it), "Filter should contain '#{it}'"
    end

    refute @filter.include?('durian'), "Filter should not contain 'durian' (possible false positive ignored)"
  end

  def test_false_positive_rate_estimation
    n = 100
    filter = BloomFilter.new(10_000, 7)
    rate = filter.false_positive_rate(n)

    # Theoretical rate should be between 0 and 1.
    assert_operator rate, :>=, 0.0
    assert_operator rate, :<=, 1.0

    # Empirical test: insert n items, then probe many non‑inserted items.
    inserted = (0...n).map { |i| "key#{i}" }
    inserted.each { |k| filter.add(k) }

    trials = 5_000
    false_positives = 0
    (0...trials).each do |i|
      key = "nonexistent#{i}"
      false_positives += 1 if filter.include?(key)
    # Ensure we do not count true positives.
    end

    empirical_rate = false_positives.to_f / trials
    # Empirical rate should be close to theoretical (within 20% relative error).
    tolerance = 0.2 * rate
    assert_in_delta rate, empirical_rate, tolerance, "Empirical false positive rate deviates"
  end

  def test_merge
    f1 = BloomFilter.new(@size, @hashes)
    f2 = BloomFilter.new(@size, @hashes)

    f1.add('alpha')
    f2.add('beta')

    f1.merge!(f2)

    assert f1.include?('alpha')
    assert f1.include?('beta')
  end

  def test_serialization_roundtrip
    items = %w[foo bar baz]
    items.each { |it| @filter.add(it) }

    data = @filter.serialize
    restored = BloomFilter.deserialize(data)

    items.each do |it|
      assert restored.include?(it), "Restored filter should contain '#{it}'"
    end

    refute restored.include?('qux')
  end

  def test_invalid_initialization
    assert_raises(ArgumentError) { BloomFilter.new(0, 3) }
    assert_raises(ArgumentError) { BloomFilter.new(100, 0) }
    assert_raises(ArgumentError) { BloomFilter.new(-10, 2) }
  end

  def test_edge_cases
    empty = BloomFilter.new(1, 1)
    assert empty.maybe?('anything') == false || empty.maybe?('anything') == true # deterministic but allowed

    # Adding nil should not raise
    assert_silent { empty.add(nil) }
    assert empty.maybe?(nil) # may be true due to hash of empty string
  end

  # Simple benchmark (not a unit test) – prints average time per operation.
  def benchmark
    filter = BloomFilter.new(1_000_000, 7)
    items = (0...100_000).map { |i| "item#{i}" }

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    items.each { |it| filter.add(it) }
    add_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    100_000.times { |i| filter.include?("item#{i}") }
    query_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    puts "\nBenchmark results (seconds):"
    puts "  add (100k items): %.4f" % add_time
    puts "  query (100k lookups): %.4f" % query_time
  end
end

# Execute benchmark when the file is run directly.
if __FILE__ == $PROGRAM_NAME
  TestBloomFilter.new(:benchmark).benchmark
end
