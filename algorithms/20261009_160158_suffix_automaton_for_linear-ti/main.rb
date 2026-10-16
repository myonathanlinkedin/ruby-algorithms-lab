# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'
require 'benchmark'

class TestSuffixAutomaton < Minitest::Test
  def test_basic_operations
    sam = SuffixAutomaton.new('ababa')
    assert sam.contains?('a')
    assert sam.contains?('ab')
    assert sam.contains?('aba')
    assert sam.contains?('baba')
    refute sam.contains?('abc')
    refute sam.contains?('baab')
    assert_equal 9, sam.distinct_substrings_count
  end

  def test_empty_string
    sam = SuffixAutomaton.new('')
    refute sam.contains?('a')
    assert_equal 0, sam.distinct_substrings_count
  end

  def test_random_vs_naive
    alphabet = ('a'..'c').to_a
    30.times do
      s = Array.new(rand(0..25)) { alphabet.sample }.join
      sam = SuffixAutomaton.new(s)

      # Naïve distinct substring count
      naive_set = {}
      (0...s.length).each do |i|
        (i...s.length).each do |j|
          naive_set[s[i..j]] = true
        end
      end
      assert_equal naive_set.size, sam.distinct_substrings_count

      # Random checks for existence
      5.times do
        i = rand(0..s.length)
        j = rand(i..s.length)
        sub = s[i...j]
        assert sam.contains?(sub), "Failed to find existing substring '#{sub}'"
      end

      # Non‑existing character
      refute sam.contains?('z')
    end
  end

  def test_performance_benchmark
    long_str = ('a'..'z').to_a.sample(200_000).join
    time = Benchmark.realtime { SuffixAutomaton.new(long_str) }
    # Construction should stay well below 2 seconds on typical hardware.
    assert_operator time, :<, 2.0
  end
end

if __FILE__ == $0
  # Running the test suite is sufficient; the benchmark is part of the tests.
end
