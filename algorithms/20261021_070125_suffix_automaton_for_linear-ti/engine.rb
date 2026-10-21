# frozen_string_literal: true

require_relative 'types'

# Suffix Automaton (SAM) implementation for linear‑time substring indexing.
#
# Guarantees:
# * Construction in O(n) time and O(n) memory for a string of length n.
# * Substring existence queries in O(m) time for a pattern of length m.
# * Number of states never exceeds 2·n − 1.
class SuffixAutomaton
  attr_reader :states

  # Creates an empty automaton.
  def initialize
    @states = []
    # Create the initial (root) state.
    @states << State.new(0, -1, {})
    @last = 0
  end

  # Builds the automaton for the given +input+ string.
  # The method may be called only once per instance.
  #
  # @param input [String] the source string (may be empty)
  # @return [void]
  def build(input)
    raise SuffixAutomatonError, 'Automaton already built' unless @states.size == 1 && @last == 0

    input.each_char { |ch| extend(ch) }
    self
  end

  # Returns true iff +pattern+ occurs as a substring of the source string.
  #
  # @param pattern [String] substring to test
  # @return [Boolean]
  def contains?(pattern)
    state_idx = 0
    pattern.each_char do |ch|
      nxt = @states[state_idx].next
      return false unless nxt.key?(ch)

      state_idx = nxt[ch]
    end
    true
  end

  # Returns the number of states in the automaton.
  #
  # @return [Integer]
  def size
    @states.size
  end

  private

  # Extends the automaton with a new character +c+.
  #
  # @param c [String] a single‑character string
  # @return [void]
  def extend(c)
    cur = State.new(@states[@last].len + 1, 0, {})
    cur_idx = @states.size
    @states << cur

    p = @last
    while p != -1 && !@states[p].next.key?(c)
      @states[p].next[c] = cur_idx
      p = @states[p].link
    end

    if p == -1
      cur.link = 0
    else
      q_idx = @states[p].next[c]
      q = @states[q_idx]

      if @states[p].len + 1 == q.len
        cur.link = q_idx
      else
        # Clone state q.
        clone = State.new(@states[p].len + 1, q.link, q.next.dup)
        clone_idx = @states.size
        @states << clone

        while p != -1 && @states[p].next[c] == q_idx
          @states[p].next[c] = clone_idx
          p = @states[p].link
        end

        q.link = clone_idx
        cur.link = clone_idx
      end
    end

    @last = cur_idx
  end
end
