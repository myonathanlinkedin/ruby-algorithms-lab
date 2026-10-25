class SweetSpotFinder
  # Initialize with an optional starting integer (default 0).
  # The algorithm searches for the smallest integer n >= start
  # such that the supplied predicate returns true.
  #
  # The predicate must be monotonic: false for all n < answer,
  # true for all n >= answer. If the predicate never becomes true,
  # a RuntimeError is raised after a reasonable bound.
  def initialize(start = 0)
    @start = start
  end

  # Find the minimal integer satisfying the predicate.
  #
  # @yield [Integer] the candidate integer
  # @return [Integer] the smallest integer for which the block returns true
  # @raise [ArgumentError] if no block is given
  # @raise [RuntimeError] if the predicate never becomes true within bounds
  def find(&predicate)
    raise ArgumentError, "A block (predicate) must be provided" unless block_given?

    low = @start
    high = low

    # Exponential search to locate an upper bound where predicate is true.
    # Guard against infinite loops by limiting the number of doublings.
    max_doublings = 60 # sufficient for 64‑bit integer range
    doublings = 0
    until predicate.call(high)
      low = high + 1
      high = (high.zero? ? 1 : high * 2)
      doublings += 1
      if doublings > max_doublings
        raise RuntimeError, "Predicate never true within reasonable bounds"
      end
    end

    # Binary search between low and high (inclusive) to pinpoint the exact sweet spot.
    while low < high
      mid = low + (high - low) / 2
      if predicate.call(mid)
        high = mid
      else
        low = mid + 1
      end
    end
    low
  end
end
