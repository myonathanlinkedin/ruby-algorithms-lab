require 'digest'

# Simple key-value pair with timestamp for versioning
class KVPair
  attr_reader :key, :value, :timestamp

  def initialize(key, value, timestamp = Time.now.to_f)
    @key = key
    @value = value
    @timestamp = timestamp
  end
end

# Bloom filter implementation using a bitset stored in an Integer
class BloomFilter
  attr_reader :size, :hash_count

  def initialize(size_bits = 1024, hash_count = 3)
    @size = size_bits
    @hash_count = hash_count
    @bits = 0
  end

  def add(item)
    hash_values(item).each { |pos| set_bit(pos) }
    self
  end

  def maybe_contains?(item)
    hash_values(item).all? { |pos| bit_set?(pos) }
  end

  # Serialize the filter to a binary string
  def marshal_dump
    [@size, @hash_count, @bits]
  end

  def marshal_load(array)
    @size, @hash_count, @bits = array
  end

  private

  def hash_values(item)
    base = item.to_s
    (0...@hash_count).map do |i|
      digest = Digest::MD5.hexdigest("#{base}:#{i}")
      digest.to_i(16) % @size
    end
  end

  def set_bit(pos)
    @bits |= (1 << pos)
  end

  def bit_set?(pos)
    (@bits & (1 << pos)) != 0
  end
end

# Metadata for an immutable SSTable
class SSTableMetadata
  attr_reader :file_path, :bloom_filter, :min_key, :max_key, :timestamp

  def initialize(file_path:, bloom_filter:, min_key:, max_key:, timestamp:)
    @file_path = file_path
    @bloom_filter = bloom_filter
    @min_key = min_key
    @max_key = max_key
    @timestamp = timestamp
  end

  # Serialize metadata (excluding bloom filter which is marshaled separately)
  def marshal_dump
    [@file_path, @bloom_filter, @min_key, @max_key, @timestamp]
  end

  def marshal_load(array)
    @file_path, @bloom_filter, @min_key, @max_key, @timestamp = array
  end
end
