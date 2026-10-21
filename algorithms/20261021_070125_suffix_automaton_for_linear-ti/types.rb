# frozen_string_literal: true

# State structure used by the suffix automaton.
# +len+  : Length of the longest string in the equivalence class.
# +link+ : Suffix link (integer index of another state, -1 for root's link).
# +next+ : Transition map (character => state index).
State = Struct.new(:len, :link, :next) do
  def initialize(len = 0, link = -1, nxt = {})
    super(len, link, nxt)
  end
end

# Custom error for invalid operations on the automaton.
class SuffixAutomatonError < StandardError; end
end
