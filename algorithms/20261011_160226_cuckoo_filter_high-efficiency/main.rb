require_relative 'core'
require 'minitest/autorun'
require 'benchmark'

class TestCuckooFilter < Minitest::Test
  def setup
    @filter = CuckooFilter.new(capacity: 2000, bucket_size: 4, fingerprint_size: 8, max_kicks: 500)
    @items = (0...1500).map { |i| "item#{i}" }
    @items.each { |it| assert @filter.insert(it), "Failed to insert #{it}" }
  end

  def test_lookup_success
    @items.each do |it|
      assert @filter.contains?(it), "Filter should contain #{it}"
    end
  end

  def test_deletion
    to_delete = @items.sample(300)
    to_delete.each { |it| assert @filter.delete(it), "Failed to delete #{it}" }
    to_delete.each { |it| refute @filter.contains?(it), "Filter should not contain deleted #{it}" }
    remaining = @items - to_delete
    remaining.each { |it| assert @filter.contains?(it), "Filter lost #{it} after deletions" }
  end

  def test_false_positive_rate
    false_queries = 5000.times.map { |i| "unknown#{i}" }
    false_positives = false_queries.count { |q| @filter.contains?(q) }
    rate = false_positives.to_f / false_queries.size
    # Expected rate for 8‑bit fingerprint ≈ 1/256 ≈ 0.0039; allow a small margin.
    assert_operator rate, :<=, 0.02, "False positive rate too high: #{rate}"
  end

  def test_capacity_overflow
    small_filter = CuckooFilter.new(capacity: 20, bucket_size: 2, fingerprint_size: 8, max_kicks: 200)
    inserted = 0
    100.times do |i|
      inserted += 1 if small_filter.insert("x#{i}")
    end
    # With such a tiny filter we expect many insertions to fail.
    assert inserted < 100, "Unexpectedly inserted all items into tiny filter"
  end

  def test_random_operations_consistency
    ops = 1000
    reference = {}
    ops.times do
      key = "k#{rand(2000)}"
      case rand(3)
      when 0
        reference[key] = true
        assert small_insert(key), "Insert failed for #{key}"
      when 1
        reference.delete(key)
        assert small_delete(key), "Delete failed for #{key}"
      when 2
        expected = reference.key?(key)
        actual = @filter.contains?(key)
        assert_equal expected, actual, "Lookup mismatch for #{key}"
      end
    end
  end

  private

  def small_insert(key)
    @filter.insert(key)
  end

  def small_delete(key)
    @filter.delete(key)
  end
end

if __FILE__ == $0
  puts "Running simple benchmark..."
  bf = CuckooFilter.new(capacity: 1_000_000, bucket_size: 4, fingerprint_size: 8)
  items = (0...1_000_000).map { |i| "bench#{i}" }

  time = Benchmark.realtime do
    items.each { |it| bf.insert(it) }
  end
  puts "Inserted 1,000,000 items in #{time.round(3)} seconds (≈#{(1_000_000 / time).round} ops/sec)"
end
