# Domain models and configuration structures for the Inkling-2-Mini Bloom filter.

# Configuration object that holds the size of the bit array (in bits) and the number
# of hash functions to use. All fields are immutable after initialization.
class BloomFilterConfig
  attr_reader :bit_size, :hash_count

  # bit_size  : Integer, total number of bits in the filter (must be > 0)
  # hash_count: Integer, number of distinct hash functions (must be > 0)
  def initialize(bit_size, hash_count)
    raise ArgumentError, 'bit_size must be a positive integer' unless bit_size.is_a?(Integer) && bit_size > 0
    raise ArgumentError, 'hash_count must be a positive integer' unless hash_count.is_a?(Integer) && hash_count > 0

    @bit_size = bit_size
    @hash_count = hash_count
  end
end

# Simple immutable value object representing the result of a membership query.
class MembershipResult
  attr_reader :present, :false_positive_probability

  # present : Boolean, true if the element is possibly present, false if definitely absent
  # false_positive_probability : Float, theoretical probability of false positive given current filter state
  def initialize(present, false_positive_probability)
    @present = !!present
    @false_positive_probability = false_positive_probability.to_f
  end
end
