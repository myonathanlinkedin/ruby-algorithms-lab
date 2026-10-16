# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'
require 'benchmark'

class ConductorTest < Minitest::Test
  def test_simple_merge_two_arrays
    c = Conductor.new
    c.add_stream([1, 4, 7])
    c.add_stream([2, 3, 6, 8])
    assert_equal [1, 2, 3, 4, 6, 7, 8], c.to_a
  end

  def test_merge_with_empty_streams
    c = Conductor.new
    c.add_stream([])
    c.add_stream([5, 10])
    c.add_stream([])
    assert_equal [5, 10], c.to_a
  end

  def test_merge_with_duplicates
    c = Conductor.new
    c.add_stream([1, 2, 2, 5])
    c.add_stream([2, 3, 4])
    c.add_stream([2, 2, 2])
    assert_equal [1, 2, 2, 2, 2, 2, 3, 4, 5], c.to_a
  end

  def test_merge_large_number_of_streams
    c = Conductor.new
    100.times { |i| c.add_stream([i, i + 100]) }
    expected = (0...200).to_a
    assert_equal expected, c.to_a
  end

  def test_lazy_enumeration
    enum = Enumerator.new do |y|
      (1..5).each { |i| y << i }
    end
    c = Conductor.new
    c.add_stream(enum)
    # The enumerator should not be exhausted before iteration.
    assert_equal false, enum.peek rescue true # peek raises StopIteration only when empty
    result = []
    c.each { |v| result << v; break if v == 3 }
    assert_equal [1, 2, 3], result
    # After partial consumption, the enumerator should still have remaining items.
    remaining = []
    enum.each { |v| remaining << v }
    assert_equal [4, 5], remaining
  end

  def test_enumerable_interface
    c = Conductor.new
    c.add_stream([10, 20])
    c.add_stream([15])
    enum = c.each
    assert_instance_of Enumerator, enum
    assert_equal [10, 15, 20], enum.to_a
  end
end

# Simple benchmark to illustrate performance characteristics.
if __FILE__ == $0
  streams = 10.times.map { (1..10_000).to_a.shuffle.sort }
  conductor = Conductor.new
  streams.each { |s| conductor.add_stream(s) }

  time = Benchmark.realtime { conductor.to_a }
  puts format('Merged %d elements from %d streams in %.4f seconds',
              streams.map(&:size).sum, streams.size, time)
end
