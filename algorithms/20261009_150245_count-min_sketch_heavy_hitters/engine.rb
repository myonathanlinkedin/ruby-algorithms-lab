# frozen_string_literal: true

require_relative 'types'

# Count‑Min Sketch implementation with deterministic hash functions.
# Provides update, estimate, and heavy‑hitter extraction.
class CountMinSketch
  attr_reader :config

  # Initialize a sketch with given width (number of counters per row)
  # and depth (number of hash rows). All counters start at zero.
  #
  # Time: O(depth) for allocation
  # Space: O(width * depth) integers
  def initialize(config)
    @config = config
    @table = Array.new(@config.depth) { Array.new(@config.width, 0) }
    @seeds = (0...@config.depth).map { |i| i * 0x9e3779b9 } # distinct 32‑bit seeds
    @item_set = {} # auxiliary map to keep observed items for heavy‑hitter queries
  end

  # Increment the count of +item+ by +delta+ (default 1).
  #
  # Time: O(depth)
  # Space: O(1) (aside from the internal table)
  def update(item, delta = 1)
    raise ArgumentError, 'delta must be positive integer' unless delta.is_a?(Integer) && delta > 0

    @config.depth.times do |row|
      col = hash(item, @seeds[row]) % @config.width
      @table[row][col] += delta
    end
    @item_set[item] = true
    self
  end

  # Return the estimated frequency of +item+.
  # The estimate is an upper bound of the true count.
  #
  # Time: O(depth)
  def estimate(item)
    min = Float::INFINITY
    @config.depth.times do |row|
      col = hash(item, @seeds[row]) % @config.width
      count = @table[row][col]
      min = count if count < min
    end
    min
  end

  # Return an array of HeavyHitter structs for all observed items
  # whose estimated frequency is at least +threshold+.
  #
  # Time: O(N * depth) where N is number of distinct observed items.
  def heavy_hitters(threshold)
    raise ArgumentError, 'threshold must be non‑negative integer' unless threshold.is_a?(Integer) && threshold >= 0

    @item_set.keys.each_with_object([]) do |item, acc|
      est = estimate(item)
      acc << HeavyHitter.new(item, est) if est >= threshold
    end
  end

  private

  # Deterministic 32‑bit mixing hash based on Ruby's built‑in hash.
  # The seed diversifies the hash across rows.
  #
  # Returns a non‑negative integer.
  def hash(item, seed)
    h = item.hash
    # Mix the seed using a simple xor‑multiply scheme.
    ((h ^ seed) * 0x85ebca6b) & 0xffffffff
  end
end
