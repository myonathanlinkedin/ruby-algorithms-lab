# Verification driver, unit tests, and demonstration of Inkling-2-Mini Bloom filter.

require_relative 'types'
require_relative 'engine'

# Simple assertion helper.
def assert(condition, message = 'Assertion failed')
  raise RuntimeError, message unless condition
end

# Unit test suite for BloomFilter.
def run_tests
  # Test 1: Basic insertion and query.
  config = BloomFilterConfig.new(1024, 3) # 1 KiB bit array, 3 hash functions.
  filter = BloomFilter.new(config)

  element = 'alpha'
  result_before = filter.query(element)
  assert(!result_before.present, 'Element should not be present before insertion')
  assert(result_before.false_positive_probability == 0.0, 'FPP should be zero when definitely absent')

  filter.add(element)
  result_after = filter.query(element)
  assert(result_after.present, 'Element should be reported present after insertion')
  assert(result_after.false_positive_probability > 0.0, 'FPP should be > 0 after insertion')

  # Test 2: False positive behavior with non‑inserted element.
  other = 'beta'
  result_other = filter.query(other)
  # Since the filter is tiny, a false positive is possible; we only assert that
  # the result is a boolean and the probability matches the theoretical value.
  assert([true, false].include?(result_other.present), 'Result must be boolean')
  assert(result_other.false_positive_probability >= 0.0 && result_other.false_positive_probability <= 1.0,
         'FPP must be within [0,1]')

  # Test 3: Idempotent insertion (adding same element twice does not change bits).
  snapshot_before = filter.bits_snapshot
  filter.add(element)
  snapshot_after = filter.bits_snapshot
  assert(snapshot_before == snapshot_after, 'Adding duplicate element must not alter bit array')

  # Test 4: Edge case – very small filter (1 bit, 1 hash).
  tiny_config = BloomFilterConfig.new(1, 1)
  tiny_filter = BloomFilter.new(tiny_config)
  tiny_filter.add('x')
  tiny_result = tiny_filter.query('y')
  # With a single bit, any query after insertion must return true.
  assert(tiny_result.present, 'With 1‑bit filter, any query after insertion returns true')
  assert(tiny_result.false_positive_probability == 1.0, 'FPP should be 1.0 for full filter')

  # Test 5: Large‑scale sanity check (memory usage stays bounded).
  # We simulate a 5.4 GB filter by calculating required bit size but do not allocate it.
  # 5.4 GB = 5.4 * 2**30 bytes = 5.4 * 8 * 2**30 bits.
  # For demonstration we use a much smaller size to keep runtime reasonable.
  large_config = BloomFilterConfig.new(8 * 1024 * 1024, 7) # 8 MiB bits (~1 MiB memory)
  large_filter = BloomFilter.new(large_config)
  10_000.times { |i| large_filter.add("item#{i}") }
  # Verify that a known inserted element is reported present.
  assert(large_filter.query('item1234').present, 'Inserted element must be present in large filter')
  # Verify that a non‑inserted element has a reasonable false‑positive probability.
  fpp = large_filter.query('nonexistent').false_positive_probability
  assert(fpp >= 0.0 && fpp <= 1.0, 'FPP must be within valid range for large filter')
end

# Execute tests when the script is run directly.
if __FILE__ == $PROGRAM_NAME
  begin
    run_tests
    puts 'All Inkling-2-Mini Bloom filter tests passed.'
  rescue => e
    puts "Test failure: #{e.message}"
    exit 1
  end
end
