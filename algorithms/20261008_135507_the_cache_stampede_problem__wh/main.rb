require_relative 'core'
require 'minitest/autorun'

class CacheStampedeTest < Minitest::Test
  def setup
    @cache = Cache.new(default_ttl: 1) # short TTL for deterministic tests
  end

  def test_basic_set_and_get
    first = @cache.get(:alpha) { 42 }
    assert_equal 42, first

    second = @cache.get(:alpha) { raise "should not compute" }
    assert_equal 42, second
  end

  def test_expiration
    @cache.get(:beta) { "first" }
    sleep 1.2
    second = @cache.get(:beta) { "second" }
    assert_equal "second", second
  end

  def test_jitter_within_bounds
    ttl = 2
    @cache.get(:gamma) { "value" }
    entry = @cache.instance_variable_get(:@store)[:gamma]

    lower = Time.now + ttl * 0.9
    upper = Time.now + ttl * 1.1
    expires_at = entry.instance_variable_get(:@expires_at)

    assert_operator expires_at, :>=, lower
    assert_operator expires_at, :<=, upper
  end

  def test_concurrent_single_computation
    counter = 0
    compute = proc { sleep 0.2; counter += 1; "computed" }

    threads = 10.times.map { Thread.new { @cache.get(:delta, ttl: 5, &compute) } }
    results = threads.map(&:value)

    assert_equal ["computed"] * 10, results
    assert_equal 1, counter
  end

  def test_exception_propagation
    compute = proc { raise RuntimeError, "boom" }

    threads = 3.times.map do
      Thread.new do
        begin
          @cache.get(:epsilon, ttl: 5, &compute)
        rescue RuntimeError => e
          e.message
        end
      end
    end

    messages = threads.map(&:value)
    assert messages.all? { |msg| msg == "boom" }
  end
end
