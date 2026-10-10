# frozen_string_literal: true

require_relative 'engine'
require 'minitest/autorun'

# Unit‑test suite for the Trie implementation.
class TestTrie < Minitest::Test
  def setup
    @trie = Trie.new
    # Populate with a deterministic dataset.
    @words = {
      'apple' => 5,
      'app' => 3,
      'application' => 2,
      'apt' => 4,
      'banana' => 7,
      'band' => 1,
      'bandana' => 2,
      'bandit' => 3,
      'cat' => 6,
      'cater' => 1
    }
    @words.each { |w, f| @trie.insert(w, f) }
  end

  def test_insert_and_frequency_increment
    @trie.insert('apple', 2)
    results = @trie.autocomplete('apple')
    assert_equal 1, results.size
    assert_equal 7, results.first.frequency
  end

  def test_autocomplete_basic
    results = @trie.autocomplete('app')
    expected = %w[apple app application]
    assert_equal expected.sort, results.map(&:word).sort
  end

  def test_autocomplete_ranking
    results = @trie.autocomplete('app')
    # Expected order: apple (5), app (3), application (2)
    expected = ['apple', 'app', 'application']
    assert_equal expected, results.map(&:word)
  end

  def test_autocomplete_limit
    results = @trie.autocomplete('b', 2)
    # Words starting with 'b' sorted by frequency: banana (7), bandit (3), bandana (2), band (1)
    expected = ['banana', 'bandit']
    assert_equal expected, results.map(&:word)
  end

  def test_autocomplete_no_match
    results = @trie.autocomplete('xyz')
    assert_empty results
  end

  def test_autocomplete_empty_prefix_returns_all_sorted
    results = @trie.autocomplete('', nil)
    # Verify top three overall frequencies.
    top_three = results.first(3).map(&:word)
    expected_top = %w[banana cat apple]
    assert_equal expected_top, top_three
  end

  def test_invalid_insert_arguments
    assert_raises(ArgumentError) { @trie.insert('', 1) }
    assert_raises(ArgumentError) { @trie.insert(nil, 1) }
    assert_raises(ArgumentError) { @trie.insert('test', 0) }
  end

  def test_invalid_autocomplete_arguments
    assert_raises(ArgumentError) { @trie.autocomplete(nil) }
    assert_raises(ArgumentError) { @trie.autocomplete('a', 0) }
    assert_raises(ArgumentError) { @trie.autocomplete('a', -5) }
  end
end

# Demonstration block (executed after tests if this file is run directly)
if __FILE__ == $PROGRAM_NAME
  puts "\n--- Demo: Auto‑completion with frequency ranking ---"
  demo_trie = Trie.new
  %w[dog dolphin dock door].each { |w| demo_trie.insert(w, rand(1..5)) }
  demo_trie.insert('dog', 3) # increase frequency

  prefix = 'do'
  suggestions = demo_trie.autocomplete(prefix, 3)
  puts "Top suggestions for prefix '#{prefix}':"
  suggestions.each do |res|
    puts "  #{res.word} (freq: #{res.frequency})"
  end
end
