require 'test/unit'
require_relative 'engine'

class TestVolatileCounter < Test::Unit::TestCase
  THREAD_COUNT = 20
  INCREMENTS_PER_THREAD = 10_000

  def test_concurrent_increment
    counter = Counter.new(0)
    threads = []

    THREAD_COUNT.times do
      threads << Thread.new do
        INCREMENTS_PER_THREAD.times { counter.increment }
      end
    end

    threads.each(&:join)

    expected = THREAD_COUNT * INCREMENTS_PER_THREAD
    assert_equal(expected, counter.value, "Counter should equal #{expected} after concurrent increments")
  end

  def test_volatile_get_set
    v = Volatile.new(5)
    assert_equal(5, v.get)

    v.set(42)
    assert_equal(42, v.get)

    v.increment(8)
    assert_equal(50, v.get)
  end

  def test_increment_type_error
    v = Volatile.new("string")
    assert_raises(TypeError) { v.increment }
  end
end

if __FILE__ == $0
  # Run the test suite when executed directly.
  Test::Unit::AutoRunner.run
end
