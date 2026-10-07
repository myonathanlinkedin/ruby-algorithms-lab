# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'engine'

class LachesisCacheTest < Minitest::Test
  def setup
    @cache = LachesisCache.new(hbm_capacity: 2, dram_capacity: 5)
  end

  def test_basic_put_and_get
    @cache.put('a', 1, 10)
    assert_equal 1, @cache.get('a')
    assert_includes @cache.hbm_keys, 'a'
  end

  def test_expiration
    @cache.put('b', 2, 0.01)
    sleep 0.02
    assert_nil @cache.get('b')
    refute_includes @cache.hbm_keys, 'b'
    refute_includes @cache.dram_keys, 'b'
  end

  def test_hbm_capacity_eviction_to_dram
    @cache.put('x', 'X', 30) # occupies HBM slot 1
    @cache.put('y', 'Y', 30) # occupies HBM slot 2
    @cache.put('z', 'Z', 30) # should cause eviction of lowest‑score (x or y) to DRAM

    assert_equal 2, @cache.hbm_keys.size
    assert_equal 1, @cache.dram_keys.size
    assert_includes (@cache.hbm_keys + @cache.dram_keys), 'z'
  end

  def test_promotion_from_dram_to_hbm
    # Fill HBM with low‑score items
    @cache.put('low1', 'L1', 5)   # low ttl, low accesses
    @cache.put('low2', 'L2', 5)

    # Insert a high‑score item directly into DRAM (forced by capacity)
    @cache.put('high', 'H', 100)
    # Simulate accesses to raise its score
    10.times { @cache.get('high') }

    # Now HBM has space after we evict a low‑score item
    @cache.put('extra', 'E', 5) # triggers promotion logic

    assert_includes @cache.hbm_keys, 'high'
    refute_includes @cache.dram_keys, 'high'
  end

  def test_dram_capacity_eviction
    cache = LachesisCache.new(hbm_capacity: 1, dram_capacity: 2)
    cache.put('a', 1, 100) # HBM
    cache.put('b', 2, 100) # DRAM
    cache.put('c', 3, 100) # DRAM (fills DRAM)
    cache.put('d', 4, 100) # Should evict lowest‑score from DRAM

    assert_equal 2, cache.dram_keys.size
    assert_includes cache.hbm_keys, 'a'
    # One of b or c must have been evicted
    remaining = cache.dram_keys
    assert (remaining == ['b'] || remaining == ['c'])
  end

  def test_zero_capacity_hbm
    cache = LachesisCache.new(hbm_capacity: 0, dram_capacity: 3)
    cache.put('x', 10, 10)
    assert_empty cache.hbm_keys
    assert_includes cache.dram_keys, 'x'
  end

  def test_negative_ttl_is_treated_as_expired
    @cache.put('neg', 99, -5)
    assert_nil @cache.get('neg')
    assert_empty @cache.hbm_keys
    assert_empty @cache.dram_keys
  end
end

# Demo execution when run directly
if __FILE__ == $PROGRAM_NAME
  puts "Running LachesisCache demo..."
  demo = LachesisCache.new(hbm_capacity: 2, dram_capacity: 4)
  demo.put('alpha', 'A', 20)
  demo.put('beta', 'B', 20)
  demo.put('gamma', 'C', 20) # forces eviction to DRAM
  puts "HBM keys: #{demo.hbm_keys.inspect}"
  puts "DRAM keys: #{demo.dram_keys.inspect}"
  puts "Accessing 'gamma' multiple times to boost its score..."
  5.times { demo.get('gamma') }
  demo.put('delta', 'D', 20) # may promote 'gamma' back to HBM
  puts "After promotion attempt:"
  puts "HBM keys: #{demo.hbm_keys.inspect}"
  puts "DRAM keys: #{demo.dram_keys.inspect}"
end
