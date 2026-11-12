# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'core'

# Test suite for MemorySafety::ContextStore.
class TestContextStore < Minitest::Test
  def setup
    @store = MemorySafety::ContextStore.new(max_age_seconds: 1, max_size: 3)
  end

  def test_set_and_get
    @store.set(:a, 10)
    assert_equal 10, @store.get(:a)
    assert_equal 1, @store.version(:a)
  end

  def test_overwrite_updates_version_and_timestamp
    @store.set(:b, 'first')
    first_version = @store.version(:b)
    sleep 0.01
    @store.set(:b, 'second')
    assert_equal 'second', @store.get(:b)
    assert_equal first_version + 1, @store.version(:b)
  end

  def test_stale_detection
    @store.set(:c, 42)
    refute @store.stale?(:c)
    sleep 1.2
    assert @store.stale?(:c)
    assert_raises(MemorySafety::StaleContextError) { @store.get(:c) }
  end

  def test_refresh_computes_when_stale
    @store.set(:d, 5)
    sleep 1.2
    refreshed = @store.refresh(:d) { 99 }
    assert_equal 99, refreshed
    assert_equal 99, @store.get(:d)
    assert_equal 2, @store.version(:d)
  end

  def test_refresh_returns_existing_when_fresh
    @store.set(:e, 'fresh')
    result = @store.refresh(:e) { 'new' }
    assert_equal 'fresh', result
    assert_equal 1, @store.version(:e)
  end

  def test_missing_key_is_stale_and_raises
    assert @store.stale?(:missing)
    assert_raises(MemorySafety::StaleContextError) { @store.get(:missing) }
    refreshed = @store.refresh(:missing) { 'created' }
    assert_equal 'created', refreshed
    assert_equal 1, @store.version(:missing)
  end

  def test_lru_eviction_respects_max_size
    @store.set(:x, 1)
    @store.set(:y, 2)
    @store.set(:z, 3)
    assert_equal 3, @store.size
    @store.set(:w, 4) # should evict least‑recently‑used (:x)
    refute @store.stale?(:y) # y was accessed recently via set
    assert_raises(MemorySafety::StaleContextError) { @store.get(:x) }
    assert_equal 3, @store.size
    assert @store.stale?(:x) # treated as missing => stale
  end

  def test_delete
    @store.set(:del, 'temp')
    assert @store.delete(:del)
    refute @store.delete(:del)
    assert @store.stale?(:del)
  end

  def test_clear
    @store.set(:a, 1)
    @store.set(:b, 2)
    @store.clear
    assert_equal 0, @store.size
    assert @store.stale?(:a)
    assert @store.stale?(:b)
  end

  def test_invalid_refresh_without_block
    @store.set(:f, 0)
    assert_raises(ArgumentError) { @store.refresh(:f) }
  end
end

# Demonstration entry point (executed when running this file directly).
if __FILE__ == $PROGRAM_NAME
  puts 'Running ContextStore demonstration...'
  store = MemorySafety::ContextStore.new(max_age_seconds: 2, max_size: 5)
  store.set(:alpha, 'A')
  puts "alpha => #{store.get(:alpha)}"
  sleep 2.5
  begin
    store.get(:alpha)
  rescue MemorySafety::StaleContextError => e
    puts "Caught expected stale error: #{e.message}"
  end
  refreshed = store.refresh(:alpha) { 'A refreshed' }
  puts "After refresh, alpha => #{refreshed}"
end
