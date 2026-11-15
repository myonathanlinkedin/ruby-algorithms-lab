# frozen_string_literal: true

require_relative 'types'
require 'digest'

# Probabilistic Bloom filter implementation.
#
# Guarantees:
# * No false negatives – if an element was added, `include?` returns true.
# * Controlled false positive probability as specified in the configuration.
#
# Time complexity:
# * add      – O(k) where k is the number of hash functions.
# * include? – O(k)
#
# Space complexity:
# * O(m) bits where m is the size of the bit array.
class BloomFilter
  attr_reader :config

  # Initialize a Bloom filter.
  #
  # Parameters:
  # * expected_items (Integer) – anticipated number of distinct elements.
  # * false_positive_rate (Float) – desired false positive probability.
  #
  # The constructor computes the optimal bit array size and hash count.
  def initialize(expected_items, false_positive_rate)
    @config = BloomFilterConfig.from_parameters(expected_items, false_positive_rate)
    @bits = Array.new(@config.bit_size, false)
  end

  # Add an element to the filter.
  #
  # The element is converted to a string via `to_s` to guarantee
  # deterministic hashing.
  def add(item)
    raise ArgumentError, 'item must respond to #to_s' unless item.respond_to?(:to_s)

    hashes_for(item).each { |pos| @bits[pos] = true }
    self
  end

  # Query whether an element is possibly in the filter.
  #
  # Returns true if the element may have been added (possible false positive),
  # false if the element is definitely not present.
  def include?(item)
    raise ArgumentError, 'item must respond to #to_s' unless item.respond_to?(:to_s)

    hashes_for(item).all? { |pos| @bits[pos] }
  end

  # Expose the raw bit array for testing/inspection (read‑only).
  def bits
    @bits.dup.freeze
  end

  private

  # Generate k distinct hash positions for a given item using double hashing.
  #
  # Double hashing formula:
  #   h_i(x) = (h1(x) + i * h2(x)) mod m
  #
  # where h1 and h2 are independent hash functions.
  def hashes_for(item)
    str = item.to_s
    h1 = Digest::MD5.hexdigest(str).to_i(16)
    h2 = Digest::SHA1.hexdigest(str).to_i(16)
    m = @config.bit_size
    (0...@config.hash_count).map { |i| (h1 + i * h2) % m }
  end
end
