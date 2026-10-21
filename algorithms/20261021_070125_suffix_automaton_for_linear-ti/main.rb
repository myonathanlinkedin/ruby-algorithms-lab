# frozen_string_literal: true

require 'test/unit'
require_relative 'engine'

# Unit‑test suite for the SuffixAutomaton implementation.
class TestSuffixAutomaton < Test::Unit::TestCase
  def test_empty_string
    sam = SuffixAutomaton.new.build('')
    assert_true sam.contains?(''), 'Empty pattern should be found in empty string'
    assert_false sam.contains?('a'), 'Non‑empty pattern cannot be found in empty string'
    assert_equal 1, sam.size, 'Automaton for empty string must have exactly one state'
  end

  def test_single_character
    sam = SuffixAutomaton.new.build('a')
    assert_true sam.contains?('a')
    assert_true sam.contains?(''), 'Empty pattern is always a substring'
    assert_false sam.contains?('b')
    assert_equal 2, sam.size, 'Single character string should yield two states'
  end

  def test_repeated_character
    str = 'aaaa'
    sam = SuffixAutomaton.new.build(str)

    %w[a aa aaa aaaa].each { |sub| assert_true sam.contains?(sub), "Should contain '#{sub}'" }
    assert_false sam.contains?('aaaaa'), 'Pattern longer than source must be absent'

    max_allowed = 2 * str.length - 1
    assert_operator sam.size, :<=, max_allowed, "State count (#{sam.size}) exceeds theoretical bound #{max_allowed}"
  end

  def test_complex_string
    str = 'ababa'
    sam = SuffixAutomaton.new.build(str)

    %w[a b ab ba aba bab abab baba ababa].each do |sub|
      assert_true sam.contains?(sub), "Should contain '#{sub}'"
    end

    %w[aa bb abc cba].each do |sub|
      assert_false sam.contains?(sub), "Should not contain '#{sub}'"
    end

    max_allowed = 2 * str.length - 1
    assert_operator sam.size, :<=, max_allowed
  end

  def test_random_strings_state_bound
    20.times do
      n = rand(1..30)
      str = Array.new(n) { ('a'..'z').to_a.sample }.join
      sam = SuffixAutomaton.new.build(str)
      max_allowed = 2 * n - 1
      assert_operator sam.size, :<=, max_allowed, "Failed bound for string '#{str}'"
    end
  end
end

# Demonstration driver (executed when the file is run directly).
if __FILE__ == $PROGRAM_NAME
  puts '--- Suffix Automaton Demo ---'
  source = 'abracadabra'
  sam = SuffixAutomaton.new.build(source)

  queries = %w[abra cad ra dab abc]
  queries.each do |q|
    puts format("Substring '%s' %s in '%s'.", q, sam.contains?(q) ? 'IS' : 'IS NOT', source)
  end

  puts "Automaton built for '#{source}' contains #{sam.size} states (≤ #{2 * source.length - 1})."
end
