# Bloom Filter implementation – pure Ruby, no external dependencies.
# Provides add, include?, merge, serialization, and false‑positive rate estimation.
# Time complexity: O(k) per operation, where k = number of hash functions.
# Space complexity: O(m) bits, where m = size of the bit array.

require 'digest'

class BloomFilter
  attr_reader :size, :hash_count, :bit_array

  # Initialize a Bloom filter.
  # size: number of bits in the filter (must be > 0)
  # hash_count: number of hash functions (must be > 0)
  def initialize(size, hash_count)
    raise ArgumentError, 'size must be positive' unless size.is_a?(Integer) && size > 0
    raise ArgumentError, 'hash_count must be positive' unless hash_count.is_a?(Integer) && hash_count > 0

    @size = size
    @hash_count = hash_count
    # Use a packed binary string as bit storage for efficiency.
    # Each byte holds 8 bits; initialize to zero bytes.
    @bit_array = "\0" * ((size + 7) / 8)
  end

  # Add an element to the filter.
  # element can be any object that responds to #to_s.
  def add(element)
    indices = hash_indices(element)
    indices.each { |i| set_bit(i) }
    self
  end

  # Check whether an element is possibly in the filter.
  # Returns true if the element may be present, false if definitely not.
  def include?(element)
    indices = hash_indices(element)
    indices.all? { |i| get_bit(i) }
  end
  alias_method :maybe?, :include?

  # Merge another Bloom filter into this one (bitwise OR).
  # Both filters must have identical size and hash_count.
  def merge!(other)
    raise ArgumentError, 'Incompatible Bloom filter' unless compatible?(other)

    @bit_array = @bit_array.bytes.zip(other.bit_array.bytes).map { |a, b| (a | b).chr }.join
    self
  end

  # Serialize the filter to a binary string.
  # Format: [4-byte size][4-byte hash_count][bit_array]
  def serialize
    [@size, @hash_count].pack('N2') + @bit_array
  end

  # Deserialize a Bloom filter from a binary string.
  # Returns a new BloomFilter instance.
  def self.deserialize(str)
    raise ArgumentError, 'String too short' if str.bytesize < 8

    size, hash_count = str[0, 8].unpack('N2')
    bit_array = str[8..-1] || ''
    raise ArgumentError, 'Bit array length mismatch' unless bit_array.bytesize == ((size + 7) / 8)

    obj = allocate
    obj.instance_variable_set(:@size, size)
    obj.instance_variable_set(:@hash_count, hash_count)
    obj.instance_variable_set(:@bit_array, bit_array)
    obj
  end

  # Estimate the false‑positive probability given an expected number of inserted items n.
  # Formula: (1 - e^{-k * n / m})^k
  def false_positive_rate(expected_items)
    raise ArgumentError, 'expected_items must be non‑negative' unless expected_items.is_a?(Numeric) && expected_items >= 0

    m = @size.to_f
    k = @hash_count.to_f
    n = expected_items.to_f
    return 0.0 if n.zero?

    prob = (1 - Math.exp(-k * n / m)) ** k
    prob
  end

  protected

  # Compute k hash indices for the given element using double hashing.
  def hash_indices(element)
    data = element.to_s

    # First hash: SHA256, second hash: MD5
    h1 = Digest::SHA256.digest(data).unpack1('Q>') # 64‑bit unsigned big‑endian
    h2 = Digest::MD5.digest(data).unpack1('Q>')

    indices = []
    @hash_count.times do |i|
      # (h1 + i * h2) mod m  – ensures uniform distribution.
      idx = (h1 + i * h2) % @size
      indices << idx
    end
    indices
  end

  # Set the bit at position idx (0‑based).
  def set_bit(idx)
    byte_idx = idx / 8
    bit_mask = 1 << (idx % 8)
    current = @bit_array.getbyte(byte_idx)
    @bit_array.setbyte(byte_idx, current | bit_mask)
  end

  # Get the bit at position idx.
  def get_bit(idx)
    byte_idx = idx / 8
    bit_mask = 1 << (idx % 8)
    (@bit_array.getbyte(byte_idx) & bit_mask) != 0
  end

  # Compatibility check for merging.
  def compatible?(other)
    other.is_a?(BloomFilter) && other.size == @size && other.hash_count == @hash_count
  end
end
