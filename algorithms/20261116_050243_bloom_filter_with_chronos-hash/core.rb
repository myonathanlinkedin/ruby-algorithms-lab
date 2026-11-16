require 'digest'

# BloomFilter implements a space‑efficient probabilistic set using multiple hash functions.
# It stores bits in an array of 64‑bit words for fast bitwise operations.
class BloomFilter
  attr_reader :num_bits, :num_hashes

  # Initialize a Bloom filter.
  # +num_bits+:: total number of bits in the filter (must be > 0)
  # +num_hashes+:: number of distinct hash functions (must be > 0)
  def initialize(num_bits, num_hashes)
    raise ArgumentError, 'num_bits must be positive' unless num_bits.is_a?(Integer) && num_bits > 0
    raise ArgumentError, 'num_hashes must be positive' unless num_hashes.is_a?(Integer) && num_hashes > 0

    @num_bits   = num_bits
    @num_hashes = num_hashes
    @word_size  = 64
    @num_words  = (num_bits + @word_size - 1) / @word_size
    @bits       = Array.new(@num_words, 0)
  end

  # Add an element to the filter.
  # +item+:: any object responding to +to_s+.
  def add(item)
    each_hash_index(item) do |idx|
      word_index = idx / @word_size
      bit_offset = idx % @word_size
      @bits[word_index] |= (1 << bit_offset)
    end
    self
  end

  # Query whether +item+ is possibly in the filter.
  # Returns true if the item may be present, false if definitely not.
  def include?(item)
    each_hash_index(item) do |idx|
      word_index = idx / @word_size
      bit_offset = idx % @word_size
      return false if (@bits[word_index] & (1 << bit_offset)).zero?
    end
    true
  end

  # Reset the filter to an empty state.
  def clear
    @bits.map! { 0 }
    self
  end

  # Estimate the false‑positive probability after inserting +n+ items.
  # Uses the classic Bloom filter formula: (1 - e^{-k n / m})^k
  # +n+:: number of inserted items (non‑negative integer)
  def false_positive_rate_estimate(n)
    raise ArgumentError, 'n must be non‑negative integer' unless n.is_a?(Integer) && n >= 0
    k = @num_hashes.to_f
    m = @num_bits.to_f
    return 0.0 if n.zero?
    prob_one_bit_zero = Math.exp(-k * n / m)
    (1.0 - prob_one_bit_zero) ** k
  end

  private

  # Yield each hash index for +item+ using the Chronos‑Hash scheme.
  # Chronos‑Hash: SHA‑256 of (item_string + seed) where seed = 0…k‑1.
  def each_hash_index(item)
    base = item.to_s
    @num_hashes.times do |i|
      digest = Digest::SHA256.hexdigest(base + i.to_s)
      idx = digest.to_i(16) % @num_bits
      yield idx
    end
  end
end
