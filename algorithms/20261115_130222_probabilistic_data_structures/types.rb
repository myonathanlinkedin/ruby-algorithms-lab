# frozen_string_literal: true

# Simple data container for Bloom filter configuration.
BloomFilterConfig = Struct.new(
  :expected_items,   # Integer: expected number of distinct items to store
  :false_positive_rate, # Float: desired probability of false positives (0 < p < 1)
  :bit_size,         # Integer: number of bits in the filter (computed)
  :hash_count        # Integer: number of hash functions (computed)
) do
  # Compute optimal bit size (m) and hash count (k) based on the
  # standard Bloom filter formulas:
  #   m = -(n * ln(p)) / (ln(2)^2)
  #   k = (m / n) * ln(2)
  #
  # Both values are rounded up to the nearest integer.
  def self.from_parameters(expected_items, false_positive_rate)
    raise ArgumentError, 'expected_items must be positive' unless expected_items.is_a?(Integer) && expected_items > 0
    raise ArgumentError, 'false_positive_rate must be between 0 and 1 (exclusive)' unless false_positive_rate.is_a?(Float) && false_positive_rate.positive? && false_positive_rate < 1.0

    ln2 = Math.log(2)
    m = -(expected_items * Math.log(false_positive_rate)) / (ln2 * ln2)
    k = (m / expected_items) * ln2

    new(
      expected_items,
      false_positive_rate,
      m.ceil,
      k.ceil
    )
  end
end
