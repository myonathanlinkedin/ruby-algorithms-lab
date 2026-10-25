require_relative 'core'
require 'minitest/autorun'

class SweetSpotFinderTest < Minitest::Test
  def test_basic_threshold
    finder = SweetSpotFinder.new
    result = finder.find { |x| x >= 10 }
    assert_equal 10, result
  end

  def test_quadratic_threshold
    finder = SweetSpotFinder.new
    result = finder.find { |x| x * x >= 50 }
    assert_equal 8, result
  end

  def test_start_at_zero_true_immediately
    finder = SweetSpotFinder.new
    result = finder.find { |x| x >= 0 }
    assert_equal 0, result
  end

  def test_custom_start
    finder = SweetSpotFinder.new(5)
    result = finder.find { |x| x >= 12 }
    assert_equal 12, result
  end

  def test_large_answer
    finder = SweetSpotFinder.new
    target = 1_000_000
    result = finder.find { |x| x >= target }
    assert_equal target, result
  end

  def test_never_true_raises
    finder = SweetSpotFinder.new
    assert_raises(RuntimeError) do
      finder.find { false }
    end
  end

  def test_no_block_raises
    finder = SweetSpotFinder.new
    assert_raises(ArgumentError) do
      finder.find
    end
  end

  # Simple benchmark to illustrate O(log n) behavior (not a strict performance test)
  def test_performance_hint
    finder = SweetSpotFinder.new
    target = 2**30
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = finder.find { |x| x >= target }
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    assert_equal target, result
    # Expect the search to complete well under a second even for huge targets.
    assert_operator elapsed, :<, 0.5
  end
end

# Demonstration entry point (executed when running this file directly)
if __FILE__ == $0
  puts "Running SweetSpotFinder demo..."
  demo_finder = SweetSpotFinder.new
  sweet_spot = demo_finder.find { |x| x * x >= 12345 }
  puts "Smallest integer whose square >= 12345 is #{sweet_spot}"
end
