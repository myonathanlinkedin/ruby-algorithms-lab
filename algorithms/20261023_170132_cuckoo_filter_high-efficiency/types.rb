# frozen_string_literal: true

# Simple bucket structure for a cuckoo filter.
# Each bucket holds a fixed number of fingerprint integers.
class Bucket
  attr_reader :slots

  def initialize(capacity)
    @capacity = capacity
    @slots = []
  end

  # Returns true if the bucket already contains the fingerprint.
  def include?(fingerprint)
    @slots.include?(fingerprint)
  end

  # Attempts to add a fingerprint.
  # Returns true on success, false if the bucket is full.
  def add(fingerprint)
    return false if @slots.size >= @capacity

    @slots << fingerprint
    true
  end

  # Removes a fingerprint if present.
  # Returns true if something was removed.
  def delete(fingerprint)
    idx = @slots.index(fingerprint)
    return false unless idx

    @slots.delete_at(idx)
    true
  end

  # Returns true if there is at least one free slot.
  def space_available?
    @slots.size < @capacity
  end

  # Randomly evicts one fingerprint and returns it.
  # Caller must ensure the bucket is not empty.
  def evict_random(rng)
    evict_idx = rng.rand(@slots.size)
    @slots.delete_at(evict_idx)
  end
end

# Configuration struct for a cuckoo filter.
CuckooConfig = Struct.new(
  :bucket_count,   # total number of buckets (must be power of two)
  :bucket_size,    # slots per bucket
  :fingerprint_bits, # bits per fingerprint
  :max_kicks,      # eviction attempts before giving up
  :seed            # deterministic RNG seed
)
