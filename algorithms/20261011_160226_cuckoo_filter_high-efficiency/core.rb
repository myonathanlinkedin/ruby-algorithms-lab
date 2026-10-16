require 'digest'

class CuckooFilter
  attr_reader :size, :capacity

  # Create a cuckoo filter.
  # capacity: expected number of items (approximate)
  # bucket_size: entries per bucket (default 4)
  # fingerprint_size: bits per fingerprint (default 8)
  # max_kicks: relocation attempts before giving up (default 500)
  def initialize(capacity:, bucket_size: 4, fingerprint_size: 8, max_kicks: 500)
    @bucket_size = bucket_size
    @fingerprint_size = fingerprint_size
    @max_kicks = max_kicks
    @num_buckets = next_power_of_two((capacity.to_f / bucket_size).ceil)
    @buckets = Array.new(@num_buckets) { [] }
    @size = 0
    @capacity = capacity
  end

  # Insert an item. Returns true on success, false on failure.
  def insert(item)
    fp = fingerprint(item)
    i1 = index_hash(item)
    i2 = alt_index(i1, fp)

    return true if add_to_bucket(i1, fp) || add_to_bucket(i2, fp)

    i = [i1, i2].sample
    cur_fp = fp

    @max_kicks.times do
      bucket = @buckets[i]
      evict_idx = rand(bucket.size)
      evicted_fp = bucket[evict_idx]
      bucket[evict_idx] = cur_fp
      cur_fp = evicted_fp
      i = alt_index(i, cur_fp)
      if add_to_bucket(i, cur_fp)
        return true
      end
    end
    false
  end

  # Returns true if the item is probably in the filter.
  def contains?(item)
    fp = fingerprint(item)
    i1 = index_hash(item)
    i2 = alt_index(i1, fp)
    bucket_contains?(i1, fp) || bucket_contains?(i2, fp)
  end

  # Delete an item. Returns true if the item was present and removed.
  def delete(item)
    fp = fingerprint(item)
    i1 = index_hash(item)
    i2 = alt_index(i1, fp)
    if remove_from_bucket(i1, fp) || remove_from_bucket(i2, fp)
      @size -= 1
      true
    else
      false
    end
  end

  private

  def add_to_bucket(idx, fp)
    bucket = @buckets[idx]
    return false if bucket.size >= @bucket_size
    bucket << fp
    @size += 1
    true
  end

  def bucket_contains?(idx, fp)
    @buckets[idx].include?(fp)
  end

  def remove_from_bucket(idx, fp)
    bucket = @buckets[idx]
    if (pos = bucket.index(fp))
      bucket.delete_at(pos)
      true
    else
      false
    end
  end

  # Compute a non‑zero fingerprint of the requested size.
  def fingerprint(item)
    h = hash(item)
    mask = (1 << @fingerprint_size) - 1
    fp = h & mask
    fp = 1 if fp.zero?
    fp
  end

  # Primary bucket index derived from the item's hash.
  def index_hash(item)
    (hash(item) >> @fingerprint_size) % @num_buckets
  end

  # Alternate bucket index derived from primary index and fingerprint.
  def alt_index(idx, fp)
    ((idx ^ hash(fp)) % @num_buckets)
  end

  # 64‑bit hash using SHA‑256, taking the first 8 bytes.
  def hash(value)
    Digest::SHA256.digest(value.to_s).unpack1('Q>') # big‑endian unsigned 64‑bit
  end

  # Round up to the next power of two (required for modulo properties).
  def next_power_of_two(n)
    p = 1
    p <<= 1 while p < n
    p
  end
end
