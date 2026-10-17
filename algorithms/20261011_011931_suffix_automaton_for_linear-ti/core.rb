class SuffixAutomaton
  State = Struct.new(:len, :link, :next, :occ)

  attr_reader :size, :last, :states, :original

  def initialize(str = "")
    @original = str.dup
    @states = []
    @size = 0
    @last = 0
    new_state(0)               # root state
    @states[0].link = -1
    str.each_char { |ch| add_char(ch) }
    compute_occurrences
  end

  # Add a character to the automaton (online construction)
  def add_char(ch)
    cur = new_state(@states[@last].len + 1)
    @states[cur].occ = 1
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
        clone = new_state(@states[p].len + 1)
        @states[clone].next = @states[q].next.dup
        @states[clone].link = @states[q].link
        @states[clone].occ = 0
        while p != -1 && @states[p].next[ch] == q
          @states[p].next[ch] = clone
          p = @states[p].link
        end
        @states[q].link = @states[cur].link = clone
      end
    end
    @last = cur
  end

  # Returns true if substr appears in the original string
  def contains?(substr)
    return true if substr.empty?
    state = 0
    substr.each_char do |ch|
      nxt = @states[state].next[ch]
      return false unless nxt
      state = nxt
    end
    true
  end

  # Returns number of (possibly overlapping) occurrences of substr
  def occurrences(substr)
    return @original.length + 1 if substr.empty?
    state = 0
    substr.each_char do |ch|
      nxt = @states[state].next[ch]
      return 0 unless nxt
      state = nxt
    end
    @states[state].occ
  end

  private

  # Create a new state, return its index
  def new_state(length)
    @states << State.new(length, -1, {}, 0)
    idx = @size
    @size += 1
    idx
  end

  # Propagate occurrence counts from longer states to their suffix links
  def compute_occurrences
    order = (0...@size).to_a.sort_by { |i| @states[i].len }
    order.reverse_each do |v|
      link = @states[v].link
      next if link == -1
      @states[link].occ += @states[v].occ
    end
  end
end
