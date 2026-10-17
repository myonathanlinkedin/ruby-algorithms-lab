# frozen_string_literal: true

require_relative 'types'

# Core Trie implementation with frequency‑aware auto‑completion.
class Trie
  attr_reader :root

  def initialize
    @root = TrieNode.new
  end

  # Inserts a word into the trie.
  # If the word already exists, its frequency is increased by +freq.
  #
  # @param word [String] the word to insert (must be non‑nil)
  # @param freq [Integer] positive increment (default: 1)
  # @raise [ArgumentError] if word is nil or empty, or freq is not positive
  def insert(word, freq = 1)
    raise ArgumentError, 'word must be a non‑empty String' unless word.is_a?(String) && !word.empty?
    raise ArgumentError, 'freq must be a positive Integer' unless freq.is_a?(Integer) && freq.positive?

    node = @root
    word.each_char do |ch|
      node.children[ch] ||= TrieNode.new
      node = node.children[ch]
    end
    node.end_of_word = true
    node.frequency += freq
    self
  end

  # Returns up to +limit+ autocomplete suggestions for +prefix+.
  # Results are sorted by descending frequency, then lexicographically.
  #
  # @param prefix [String] the prefix to search for (may be empty)
  # @param limit [Integer, nil] maximum number of results (nil => no limit)
  # @return [Array<Result>]
  def autocomplete(prefix, limit = nil)
    raise ArgumentError, 'prefix must be a String' unless prefix.is_a?(String)
    raise ArgumentError, 'limit must be nil or a positive Integer' unless limit.nil? || (limit.is_a?(Integer) && limit.positive?)

    node = @root
    prefix.each_char do |ch|
      node = node.children[ch]
      return [] unless node
    end

    results = []
    collect(node, prefix, results)

    results.sort!
    limit ? results.first(limit) : results
  end

  private

  # Depth‑first traversal collecting all words beneath +node+.
  #
  # @param node [TrieNode] current node
  # @param current_word [String] word built so far
  # @param results [Array<Result>] accumulator
  def collect(node, current_word, results)
    if node.end_of_word
      results << Result.new(current_word, node.frequency)
    end
    node.children.each do |ch, child|
      collect(child, current_word + ch, results)
    end
  end
end
