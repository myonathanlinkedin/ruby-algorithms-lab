# frozen_string_literal: true

require_relative 'engine'

# Simple assertion helper.
def assert(condition, message = 'Assertion failed')
  raise message unless condition
end

# Deterministic test suite for CuckooFilter.
def run_tests
  # Test 1: Basic insert / lookup / delete cycle.
  filter = CuckooFilter.new
  items = %w[apple banana cherry date elderberry fig grape]

  items.each { |it| assert(filter.insert(it), "Failed to insert #{it}") }
  items.each { |it| assert(filter.lookup(it), "Lookup failed for #{it}") }

  # Delete a subset and verify.
  delete_set = %w[banana date]
  delete_set.each { |it| assert(filter.delete(it), "Delete failed for #{it}") }
  delete_set.each { |it| assert(!filter.lookup(it), "Item still present after delete: #{it}") }

  # Ensure remaining items are still found.
  (items - delete_set).each { |it| assert(filter.lookup(it), "Missing after deletions: #{it}") }

  # Test 2: Insertion until full (or near‑full) and verify load factor bounds.
  small_cfg = CuckooConfig.new(
    1 << 6,   # 64 buckets
    2,        # 2 slots per bucket (tight capacity)
    8,
    200,
    12345
  )
  small_filter = CuckooFilter.new(small_cfg)
  inserted = 0
  10_000.times do |i|
    break unless small_filter.insert("key#{i}")
    inserted += 1
  end
  assert(inserted > 0, 'No items inserted into small filter')
  assert(small_filter.load_factor <= 0.95, "Load factor too high: #{small_filter.load_factor}")

  # Test 3: False positive rate sanity check.
  # With a fresh filter, insert N items, then query M non‑inserted items.
  cfg = CuckooConfig.new(1 << 10, 4, 8, 500, 777)
  fp_filter = CuckooFilter.new(cfg)
  n = 500
  m = 5_000
  n.times { |i| fp_filter.insert("elem#{i}") }
  false_positives = 0
  m.times { |i| false_positives += 1 if fp_filter.lookup("nonexistent#{i}") }
  observed_fp_rate = false_positives.to_f / m
  # Expected false positive rate for 8‑bit fingerprint ≈ 1/256 ≈ 0.0039.
  assert(observed_fp_rate < 0.02, "False positive rate too high: #{observed_fp_rate}")

  # Test 4: Edge case – inserting duplicate items.
  dup_filter = CuckooFilter.new
  assert(dup_filter.insert('dup'), 'First insert failed')
  assert(dup_filter.insert('dup'), 'Second insert (duplicate) failed')
  # Deleting once should still leave one copy.
  assert(dup_filter.delete('dup'), 'Delete of duplicate failed')
  assert(dup_filter.lookup('dup'), 'Item missing after single delete of duplicate')
  # Delete second copy.
  assert(dup_filter.delete('dup'), 'Second delete failed')
  assert(!dup_filter.lookup('dup'), 'Item still present after deleting both copies')

  puts 'All tests passed.'
end

# Execute test suite when the file is run directly.
if __FILE__ == $PROGRAM_NAME
  run_tests
end
