require 'minitest/autorun'
require_relative 'core'

class TestSuffixAutomaton < Minitest::Test
  def test_empty_string
    sam = SuffixAutomaton.new("")
    assert sam.contains?("")
    refute sam.contains?("a")
    assert_equal 1, sam.occurrences("")
    assert_equal 0, sam.occurrences("a")
  end

  def test_single_character
    sam = SuffixAutomaton.new("a")
    assert sam.contains?("a")
    refute sam.contains?("b")
    assert_equal 1, sam.occurrences("a")
    assert_equal 0, sam.occurrences("b")
    assert_equal 2, sam.occurrences("")
  end

  def test_repeated_characters
    sam = SuffixAutomaton.new("aaa")
    assert sam.contains?("a")
    assert sam.contains?("aa")
    assert sam.contains?("aaa")
    refute sam.contains?("aaaa")
    assert_equal 3, sam.occurrences("a")
    assert_equal 2, sam.occurrences("aa")
    assert_equal 1, sam.occurrences("aaa")
    assert_equal 0, sam.occurrences("aaaa")
    assert_equal 4, sam.occurrences("")
  end

  def test_complex_string
    str = "ababa"
    sam = SuffixAutomaton.new(str)
    substrings = {
      "a" => 3,
      "b" => 2,
      "ab" => 2,
      "ba" => 2,
      "aba" => 2,
      "bab" => 1,
      "ababa" => 1,
      "c" => 0,
      "aa" => 0
    }
    substrings.each do |sub, cnt|
      assert_equal cnt > 0, sam.contains?(sub), "contains? failed for #{sub}"
      assert_equal cnt, sam.occurrences(sub), "occurrences failed for #{sub}"
    end
    assert_equal str.length + 1, sam.occurrences("")
  end

  def test_unicode_support
    str = "αβγαβ"
    sam = SuffixAutomaton.new(str)
    assert sam.contains?("αβ")
    assert_equal 2, sam.occurrences("αβ")
    refute sam.contains?("δ")
    assert_equal 0, sam.occurrences("δ")
  end

  def test_incremental_construction
    sam = SuffixAutomaton.new
    "abcab".each_char { |ch| sam.add_char(ch) }
    assert sam.contains?("cab")
    assert_equal 1, sam.occurrences("cab")
    assert sam.contains?("ab")
    assert_equal 2, sam.occurrences("ab")
  end
end

# Simple benchmark (optional, not part of unit tests)
if __FILE__ == $0
  require 'benchmark'

  str = "a" * 100_000
  puts "Building SAM for string of length #{str.length}..."
  time = Benchmark.realtime { SuffixAutomaton.new(str) }
  puts "Construction time: #{time.round(3)} seconds"
end
