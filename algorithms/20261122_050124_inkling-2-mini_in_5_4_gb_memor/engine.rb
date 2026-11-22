# Core algorithmic implementation of the Inkling-2-Mini Bloom filter.

require 'digest'

# The BloomFilter class implements a space‑efficient probabilistic set.
# It uses a bit array stored as an Array of Integer (each integer holds 64 bits).
# All operations are deterministic and run in O(k) time where k = hash_count.
class BloomFilter
  WORD_SIZE = 64 # Number of bits per Integer word

  # Initialize a new Bloom filter with the given configuration.
  # config : BloomFilterConfig
  def initialize(config)
    raise ArgumentError, 'config must be a BloomFilterConfig' unless config.is_a?(BloomFilterConfig)

    @bit_size = config.bit_size
    @hash_count = config.hash_count

    # Compute number of words needed to store @bit_size bits.
    @word_count = (@bit_size + WORD_SIZE - 1) / WORD_SIZE
    @bits = Array.new(@word_count, 0)

    # Pre‑compute salts for hash functions to avoid recomputing strings.
    @salts = (0...@hash_count).map { |i| i.to_s }
  end

  # Add an element (any object that responds to #to_s) to the filter.
  # Returns self to allow method chaining.
  def add(element)
    positions = hash_positions(element)
    positions.each { |pos| set_bit(pos) }
    self
  end

  # Query whether an element is possibly in the set.
  # Returns a MembershipResult.
  def query(element)
    positions = hash_positions(element)
    present = positions.all? { |pos| get_bit(pos) }
    false_positive_probability = present ? theoretical_fpp : 0.0
    MembershipResult.new(present, false_positive_probability)
  end

  # Expose the raw bit array for testing purposes (read‑only copy).
  def bits_snapshot
    @bits.dup
  end

  private

  # Compute k hash positions for the given element.
  # Returns an Array of Integer positions in the range [0, @bit_size).
  def hash_positions(element)
    # Use MD5 as base hash; split the 128‑bit digest into 4 32‑bit chunks.
    base_digest = Digest::MD5.hexdigest(element.to_s)
    # Convert hex string to integer array.
    chunks = base_digest.scan(/.{8}/).map { |hex| hex.to_i(16) }

    positions = []
    @hash_count.times do |i|
      # Combine chunk i (modulo number of chunks) with a salt to obtain a new hash.
      combined = Digest::MD5.hexdigest(@salts[i] + chunks[i % chunks.length].to_s)
      # Use first 8 hex chars (32 bits) as integer.
      hash_val = combined[0, 8].to_i(16)
      positions << (hash_val % @bit_size)
    end
    positions
  end

  # Set the bit at the given position to 1.
  def set_bit(pos)
    word_index = pos / WORD_SIZE
    bit_index = pos % WORD_SIZE
    @bits[word_index] |= (1 << bit_index)
  end

  # Retrieve the bit at the given position (true/false).
  def get_bit(pos)
    word_index = pos / WORD_SIZE
    bit_index = pos % WORD_SIZE
    ((@bits[word_index] >> bit_index) & 1) == 1
  end

  # Compute the theoretical false‑positive probability based on current fill ratio.
  # Uses the standard Bloom filter formula: (1 - e^(-k * n / m))^k
  # where n = number of inserted elements (estimated by bit density),
  # m = @bit_size, k = @hash_count.
  def theoretical_fpp
    m = @bit_size.to_f
    k = @hash_count.to_f
    # Estimate n by counting set bits.
    set_bits = @bits.reduce(0) { |sum, word| sum + word.to_s(2).count('1') }
    n = set_bits / k # rough estimate; over‑estimates n slightly but safe for demonstration
    probability = (1 - Math.exp(-k * n / m))**k
    probability
  end
end
