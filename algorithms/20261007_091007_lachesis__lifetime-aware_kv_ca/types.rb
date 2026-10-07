# frozen_string_literal: true

# Simple enumeration for cache tiers
module Tier
  HBM = :hbm   # High Bandwidth Memory (fast, limited)
  DRAM = :dram # Main memory (slower, larger)
end

# Represents a cached key‑value entry with lifetime awareness
class CacheItem
  attr_reader :key, :value, :ttl, :created_at
  attr_accessor :access_count, :tier

  # ttl: time‑to‑live in seconds (Float)
  def initialize(key:, value:, ttl:, tier:)
    @key = key
    @value = value
    @ttl = ttl.to_f
    @created_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @access_count = 0
    @tier = tier
  end

  # Remaining lifetime in seconds; may be negative if expired
  def remaining_lifetime
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @created_at
    @ttl - elapsed
  end

  # Whether the item is still valid
  def alive?
    remaining_lifetime.positive?
  end

  # Simple score: higher access count and longer remaining lifetime => higher score
  # Used for eviction decisions (lower score evicted first)
  def score
    return 0.0 unless alive?
    # Avoid division by zero; add a tiny epsilon
    @access_count.to_f / (remaining_lifetime + 1e-9)
  end
end
