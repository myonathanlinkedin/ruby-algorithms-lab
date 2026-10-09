# frozen_string_literal: true

# Suffix Automaton implementation for linear‑time substring indexing.
# Provides O(|S|) construction, O(|P|) substring queries, and O(|S|)
# distinct substring counting.
class SuffixAutomaton
  State = Struct.new(:len, :link, :next)

  # Build automaton for the given string.
  # @param str [String] the source string (may be empty)
  def initialize(str = '')
    @states = []
    @size = 0
    @last = 0
    create_state(0, -1) # root
    str.each_char { |ch| add_char(ch) }
  end

  # Returns true if pattern appears as a substring.
  # @param pat [String] pattern to search
  # @return [Boolean]
  def contains?(pat)
    v = 0
    pat.each_char do |ch|
      nxt = @states[v].next[ch]
      return false unless nxt
      v = nxt
    end
    true
  end

  # Number of distinct substrings of the original string.
  # Formula: Σ (len(v) - len(link(v))) over all states v ≠ root.
  # @return [Integer]
  def distinct_substrings_count
    count = 0
    @states.each_with_index do |st, idx|
      next if idx.zero? # skip root
      link_len = @states[st.link].len
      count += st.len - link_len
    end
    count
  end

  private

  # Create a new state with given length and suffix link.
  # @param len [Integer] maximum length of strings reaching this state
  # @param link [Integer] suffix link index
  # @return [Integer] index of the created state
  def create_state(len, link)
    @states << State.new(len, link, {})
    @size += 1
    @size - 1
  end

  # Extend automaton with a new character.
  # @param ch [String] single character
  def add_char(ch)
    cur = create_state(@states[@last].len + 1, 0)
    p = @last
    while p != -1 && !@states[p].next.key?(ch)
      @states[p].next[ch] = cur
      p = @states[p].link
    end
    if p == -1
      @states[cur].link = 0
    else
      q = @states[p].next[ch]
      if @states[p].len + 1 == @states[q].len
        @states[cur].link = q
      else
        clone = create_state(@states[p].len + 1, @states[q].link)
        @states[clone].next.merge!(@states[q].next)
        while p != -1 && @states[p].next[ch] == q
          @states[p].next[ch] = clone
          p = @states[p].link
        end
        @states[q].link = @states[cur].link = clone
      end
    end
    @last = cur
  end
end
