require 'minitest/autorun'
require_relative 'core'

class TestCountMinSketch < Minitest::Test
  def setup
    @width = 1000
    @depth = 5
    @cms = CountMinSketch.new(width: @width, depth: @depth, seed: 42)
  end

  def test_add_and_estimate_basic
    @cms.add('apple')
    @cms.add('banana', 3)
    @cms.add('apple', 2)

    assert_equal 3, @cms.estimate('apple')
    assert_equal 3, @cms.estimate('banana')
    assert_equal 0, @cms.estimate('cherry')
  end

  def test_estimate_never_underestimates
    # Insert many items to increase collision probability
    10_000.times { |i| @cms.add("key#{i}") }
    @cms.add('target', 5)

    # Estimate should be at least the true count
    assert_operator @cms.estimate('target'), :>=, 5
  end

  def test_heavy_hitters
    data = %w[dog cat mouse dog cat dog rabbit cat]
    data.each { |item| @cms.add(item) }

    candidates = %w[dog cat mouse rabbit elephant]
    hitters = @cms.heavy_hitters(candidates, 3)
    assert_includes hitters, 'dog'
    assert_includes hitters, 'cat'
    refute_includes hitters, 'mouse'
    refute_includes hitters, 'rabbit'
    refute_includes hitters, 'elephant'
  end

  def test_error_bound
    # With width = 1000, ε ≈ 2/width = 0.002
    epsilon = 2.0 / @width
    total = 0
    5_000.times do |i|
      count = rand(1..5)
      @cms.add("item#{i}", count)
      total += count
    end
    # For any item, overestimation ≤ ε * total with probability ≥ 1 - 2^-depth
    @cms.tables.each do |row|
      row.each do |val|
        assert_operator val, :<=, total * (1 + epsilon) + 1 # small slack for integer rounding
      end
    end
  end
end

# Demonstration when run directly (outside test harness)
if __FILE__ == $0 && !defined?(Minitest)
  cms = CountMinSketch.new(width: 500, depth: 4, seed: 123)
  stream = %w[alpha beta gamma alpha delta beta alpha epsilon gamma alpha]
  stream.each { |item| cms.add(item) }

  puts "Estimated frequencies:"
  %w[alpha beta gamma delta epsilon zeta].each do |item|
    puts "#{item.ljust(7)} : #{cms.estimate(item)}"
  end

  puts "\nHeavy hitters (threshold ≥ 3):"
  puts cms.heavy_hitters(%w[alpha beta gamma delta epsilon], 3).inspect
end
