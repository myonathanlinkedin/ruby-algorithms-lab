class CountMinSketch
  attr_reader :width, :depth, :tables, :hash_seeds

  # width: number of columns (error bound ε ≈ 2/width)
  # depth: number of rows (confidence δ ≈ 1/2^depth)
  def initialize(width:, depth:, seed: nil)
    raise ArgumentError, "width and depth must be positive integers" unless width.is_a?(Integer) && depth.is_a?(Integer) && width > 0 && depth > 0

    @width = width
    @depth = depth
    @tables = Array.new(depth) { Array.new(width, 0) }
    rng = seed ? Random.new(seed) : Random.new
    @hash_seeds = Array.new(depth) { rng.rand(0..0xffffffff) }
  end

  # Increment the count of +item+ by +count+ (default 1)
  def add(item, count = 1)
    raise ArgumentError, "count must be a non‑negative integer" unless count.is_a?(Integer) && count >= 0
    hash = item.hash
    @depth.times do |i|
      idx = ((hash ^ @hash_seeds[i]) & 0xffffffff) % @width
      @tables[i][idx] += count
    end
    self
  end

  # Return the estimated frequency of +item+
  def estimate(item)
    hash = item.hash
    min = Float::INFINITY
    @depth.times do |i|
      idx = ((hash ^ @hash_seeds[i]) & 0xffffffff) % @width
      val = @tables[i][idx]
      min = val if val < min
    end
    min
  end

  # Given an enumerable +candidates+ and a +threshold+, return those items whose estimated frequency ≥ threshold
  def heavy_hitters(candidates, threshold)
    raise ArgumentError, "threshold must be a non‑negative integer" unless threshold.is_a?(Integer) && threshold >= 0
    candidates.select { |item| estimate(item) >= threshold }
  end
end
