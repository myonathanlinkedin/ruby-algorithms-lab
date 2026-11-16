require 'minitest/autorun'
require 'benchmark'
require_relative 'core'

# Unit‑test suite for BloomFilter.
class TestBloomFilter < Minitest::Test
  def setup
    @bits   = 1024
    @hashes = 4
    @filter = BloomFilter.new(@bits, @hashes)
  end

  def test_basic_add_and_query
    assert_equal false, @filter.include?('alice')
    @filter.add('alice')
    assert @filter.include?('alice')
    refute @filter.include?('bob')
    @filter.add('bob')
    assert @filter.include?('bob')
  end

  def test_idempotent_add
    3.times { @filter.add('charlie') }
    assert @filter.include?('charlie')
  end

  def test_clear
    @filter.add('delta')
    assert @filter.include?('delta')
    @filter.clear
    refute @filter.include?('delta')
  end

  def test_false_positive_rate_estimate
    n = 100
    rate = @filter.false_positive_rate_estimate(n)
    assert_in_delta 0.0, rate, 0.5 # Very rough bound for small filter
    # Empirical check
    inserted = (1..n).map { |i| "item#{i}" }
    inserted.each { |x| @filter.add(x) }
    false_positives = 0
    trials = 10_000
    trials.times do
      candidate = "unknown#{rand(1_000_000)}"
      false_positives += 1 if @filter.include?(candidate)
    end
    empirical = false_positives.to_f / trials
    # Empirical rate should not exceed theoretical by more than 5× for this tiny filter
    assert_operator empirical, :<=, rate * 5 + 0.01
  end

  def test_edge_cases
    # Zero‑length filter is prohibited; ensure exception.
    assert_raises(ArgumentError) { BloomFilter.new(0, 1) }
    assert_raises(ArgumentError) { BloomFilter.new(10, 0) }

    # Very large number of hash functions (but still functional)
    large_hashes = BloomFilter.new(2048, 16)
    large_hashes.add('epsilon')
    assert large_hashes.include?('epsilon')
  end
end

# Simple benchmark demonstrating throughput.
if __FILE__ == $0
  puts 'Benchmark: inserting 100_000 elements into a 1 MiB filter (8 k bits, 7 hashes)'
  bits   = 8 * 1024 # 8 k bits ≈ 1 KiB
  hashes = 7
  bf = BloomFilter.new(bits, hashes)

  n = 100_000
  duration = Benchmark.realtime do
    n.times { |i| bf.add("key#{i}") }
  end
  puts "Time elapsed: #{duration.round(3)} s (#{(n / duration).round} ops/s)"
end
