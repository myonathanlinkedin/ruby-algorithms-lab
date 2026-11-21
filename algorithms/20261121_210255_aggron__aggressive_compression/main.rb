# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'

class TestKVCache < Minitest::Test
  def setup
    @cache = Aggron::KVCache.new(capacity: 3, stall_threshold: 2)
  end

  def test_basic_set_get
    @cache.set('a', 1)
    @cache.set('b', 'hello')
    assert_equal 1, @cache.get('a')
    assert_equal 'hello', @cache.get('b')
  end

  def test_lru_eviction
    @cache.set('x', 10)
    @cache.set('y', 20)
    @cache.set('z', 30)
    # Access 'x' to make it most recent.
    assert_equal 10, @cache.get('x')
    # Adding fourth entry should evict 'y' (least recent).
    @cache.set('w', 40)
    assert_nil @cache.get('y')
    assert_equal 10, @cache.get('x')
    assert_equal 30, @cache.get('z')
    assert_equal 40, @cache.get('w')
  end

  def test_stall_detection
    assert_equal 0, @cache.miss_streak
    assert_nil @cache.get('missing1')
    assert_equal 1, @cache.miss_streak
    refute @cache.stall?
    assert_nil @cache.get('missing2')
    assert_equal 2, @cache.miss_streak
    assert @cache.stall?
  end

  def test_compression
    long_str = 'aaaaabbbbcccccdddddeeeee' # 5a4b5c5d5e
    @cache.set('k1', long_str)
    @cache.set('k2', 'short')
    @cache.set('k3', 123) # non‑string, should be ignored

    # Ensure stall condition to trigger compression in realistic scenario.
    @cache.get('nope')
    @cache.get('nope2')
    assert @cache.stall?

    compressed = @cache.compress!
    assert_equal 1, compressed # only k1 should be compressed

    # Verify stored value is compressed.
    entry = @cache.instance_variable_get(:@store)['k1']
    assert entry.compressed
    assert_equal 'a5b4c5d5e5', entry.value

    # Retrieval should decompress automatically.
    assert_equal long_str, @cache.get('k1')
    # Non‑compressed entries remain unchanged.
    assert_equal 'short', @cache.get('k2')
    assert_equal 123, @cache.get('k3')
  end

  def test_no_compression_when_not_beneficial
    @cache.set('k', 'abc') # compression would be longer.
    @cache.compress!
    entry = @cache.instance_variable_get(:@store)['k']
    refute entry.compressed
    assert_equal 'abc', @cache.get('k')
  end

  def test_multiple_compressions_idempotent
    str = 'xxxxxyyyyyzzzz'
    @cache.set('a', str)
    @cache.compress!
    first = @cache.instance_variable_get(:@store)['a'].value
    @cache.compress!
    second = @cache.instance_variable_get(:@store)['a'].value
    assert_equal first, second
    assert_equal str, @cache.get('a')
  end
end

# Demonstration entrypoint (executed when file is run directly)
if __FILE__ == $PROGRAM_NAME
  puts 'Demo: Aggressive KV Cache with compression'
  cache = Aggron::KVCache.new(capacity: 2, stall_threshold: 3)
  cache.set('alpha', 'aaaaaaaaaa')
  cache.set('beta', 'bbbb')
  puts "Before compression:"
  puts "alpha => #{cache.get('alpha')}"
  puts "beta => #{cache.get('beta')}"
  # Force stall
  3.times { cache.get('missing') }
  puts "Stall detected? #{cache.stall?}"
  cache.compress!
  puts "After compression:"
  puts "alpha => #{cache.get('alpha')}"
  puts "beta => #{cache.get('beta')}"
end
