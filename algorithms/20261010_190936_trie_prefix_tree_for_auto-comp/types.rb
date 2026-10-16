# frozen_string_literal: true

# Data structures used by the Trie implementation.

# Represents a node in the prefix tree.
class TrieNode
  attr_accessor :children, :end_of_word, :frequency

  def initialize
    # Mapping from character (String) to TrieNode
    @children = {}
    @end_of_word = false
    @frequency = 0
  end
end

# Immutable result object for autocomplete suggestions.
# Contains the full word and its accumulated frequency.
Result = Struct.new(:word, :frequency) do
  def <=>(other)
    # Primary: higher frequency first.
    # Secondary: lexical order ascending.
    cmp = other.frequency <=> frequency
    cmp.zero? ? word <=> other.word : cmp
  end
end
