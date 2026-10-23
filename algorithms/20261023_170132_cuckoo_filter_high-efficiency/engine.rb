# frozen_string_literal: true

require_relative 'types'
require 'digest'

# Core cuckoo filter implementation.
class CuckooFilter
  attr_reader :config, :buckets

  # Initialize a filter with the given configuration.
  # If config is nil, a sensible default is used.
  def initialize(config = nil)
    @config = config || CuckooConfig.new(
      1 << 10,   # 1024 buckets
      4,         # 4 slots per bucket
      8,         # 8‑bit fingerprint
      500,       # max eviction attempts
      42_424     # deterministic RNG seed
    )
    validate_config!
    @buckets = Array.new(@config.bucket_count) { Bucket.new(@config.bucket_size) }
    @rng = Random.new(@config.seed)
  end

  # Insert an item (any object that responds to #to_s).
  # Returns true on success, false if the filter is full.
  def insert(item)
    fp = fingerprint(item)
    i1 = index_hash(item)
    i2 = alt_index(i1, fp)

    return true if bucket(i1).add(fp) || bucket(i2).add(fp)

    cur_fp = fp
    cur_idx = i1
    @config.max_kicks.times do
      evicted_fp = bucket(cur_idx).evict_random(@rng)
      bucket(cur_idx).add(cur_fp)
      cur_fp = evicted_fp
      cur_idx = alt_index(cur_idx, cur_fp)
      return true if bucket(cur_idx).add(cur_fp)
    end
    false # filter is considered full
  end

  # Returns true if the item is possibly in the filter.
  def lookup(item)
    fp = fingerprint(item)
    i1 = index_hash(item)
    i2 = alt_index(i1, fp)
    bucket(i1).include?(fp) || bucket(i2).include?(fp)
  end

  # Deletes one occurrence of the item.
  # Returns true if an entry was removed, false otherwise.
  def delete(item)
    fp = fingerprint(item)
    i1 = index_hash(item)
    i2 = alt_index(i1, fp)
    return true if bucket(i1).delete(fp)
    return true if bucket(i2).delete(fp)
    false
  end

  # Returns the current load factor (0.0 .. 1.0).
  def load_factor
    total = @buckets.sum { |b| b.slots.size }
    total.to_f / (@config.bucket_count * @config.bucket_size)
  end

  private

  # Validate configuration constraints.
  def validate_config!
    unless @config.bucket_count.is_a?(Integer) && @config.bucket_count > 0 && (@config.bucket_count & (@config.bucket_count - 1)).zero?
      raise ArgumentError, 'bucket_count must be a positive power of two'
    end
    unless @config.bucket_size.is_a?(Integer) && @config.bucket_size > 0
      raise ArgumentError, 'bucket_size must be a positive integer'
    end
    unless @config.fingerprint_bits.is_a?(Integer) && @config.fingerprint_bits > 0 && @config.fingerprint_bits <= 32
      raise ArgumentError, 'fingerprint_bits must be between 1 and 32'
    end
    unless @config.max_kicks.is_a?(Integer) && @config.max_kicks > 0
      raise ArgumentError, 'max_kicks must be a positive integer'
    end
  end

  # Compute the fingerprint (as an integer) for an item.
  def fingerprint(item)
    hash = Digest::SHA256.digest(item.to_s)
    # Take the lower fingerprint_bits bits.
    fp = hash.unpack1('Q>') & ((1 << @config.fingerprint_bits) - 1)
    # Fingerprint must never be zero (to avoid degenerate index loops).
    fp = 1 if fp.zero?
    fp
  end

  # Primary bucket index for an item.
  def index_hash(item)
    hash = Digest::SHA256.digest(item.to_s)
    # Use the higher bits for the index to reduce correlation with fingerprint.
    idx = hash.unpack1('Q>') >> @config.fingerprint_bits
    idx & (@config.bucket_count - 1)
  end

  # Alternate index given one index and a fingerprint.
  def alt_index(idx, fingerprint)
    # The xor of the fingerprint hash with the current index.
    fp_hash = fingerprint_hash(fingerprint)
    (idx ^ fp_hash) & (@config.bucket_count - 1)
  end

  # Simple hash of a fingerprint to spread bits.
  def fingerprint_hash(fp)
    # Mix the fingerprint using a cheap multiplicative hash.
    ((fp * 0x5bd1e995) & 0xffffffff) >> (32 - Math.log2(@config.bucket_count).to_i)
  end

  def bucket(idx)
    @buckets[idx]
  end
end
