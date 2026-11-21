# frozen_string_literal: true

module Aggron
  # Simple run‑length encoding for strings.
  module RLE
    module_function

    # Compress a string using run‑length encoding.
    # Example: 'aaabb' => 'a3b2'
    def compress(str)
      return '' if str.empty?

      result = +''
      count = 1
      prev = str[0]

      str.each_char.with_index(1) do |ch, idx|
        if ch == prev
          count += 1
        else
          result << prev
          result << count.to_s if count > 1
          prev = ch
          count = 1
        end
      end

      result << prev
      result << count.to_s if count > 1
      result
    end

    # Decompress a string produced by +compress+.
    def decompress(str)
      return '' if str.empty?

      result = +''
      i = 0
      while i < str.length
        ch = str[i]
        i += 1
        num = +''
        while i < str.length && str[i] =~ /\d/
          num << str[i]
          i += 1
        end
        repeat = num.empty? ? 1 : num.to_i
        result << ch * repeat
      end
      result
    end
  end

  # KVCache implements a fixed‑capacity key‑value store with LRU eviction.
  # When a head‑of‑line stall is detected, it aggressively compresses
  # string values using run‑length encoding.
  class KVCache
    Entry = Struct.new(:key, :value, :compressed, keyword_init: true)

    # +capacity+ is the maximum number of entries the cache can hold.
    # +stall_threshold+ is the number of consecutive misses that trigger a stall.
    def initialize(capacity:, stall_threshold: 5)
      raise ArgumentError, 'capacity must be positive' unless capacity.is_a?(Integer) && capacity > 0

      @capacity = capacity
      @stall_threshold = stall_threshold
      @store = {}                # key => Entry
      @order = []                # keys in LRU order, oldest first
      @miss_streak = 0
    end

    # Retrieve the value for +key+. Returns +nil+ if missing.
    # Updates LRU order on hit.
    def get(key)
      entry = @store[key]
      if entry
        touch(key)
        @miss_streak = 0
        entry.compressed ? RLE.decompress(entry.value) : entry.value
      else
        @miss_streak += 1
        nil
      end
    end

    # Store +value+ under +key+. Evicts LRU entry if capacity is exceeded.
    # Resets stall counter.
    def set(key, value)
      if @store.key?(key)
        @store[key].value = value
        @store[key].compressed = false
        touch(key)
      else
        evict_if_needed
        @store[key] = Entry.new(key: key, value: value, compressed: false)
        @order << key
      end
      @miss_streak = 0
      self
    end

    # Returns true if a head‑of‑line stall condition is active.
    def stall?
      @miss_streak >= @stall_threshold
    end

    # Aggressively compresses all string values in the cache.
    # Returns the number of entries that were compressed.
    def compress!
      compressed_count = 0
      @store.each_value do |entry|
        next if entry.compressed
        next unless entry.value.is_a?(String)

        compressed = RLE.compress(entry.value)
        # Only keep compression if it shortens the representation.
        if compressed.length < entry.value.length
          entry.value = compressed
          entry.compressed = true
          compressed_count += 1
        end
      end
      compressed_count
    end

    # Expose internal size for testing.
    def size
      @store.size
    end

    # Expose current miss streak for testing.
    def miss_streak
      @miss_streak
    end

    private

    # Move +key+ to the most‑recent position in LRU order.
    def touch(key)
      @order.delete(key)
      @order << key
    end

    # Evict the least‑recently used entry if capacity would be exceeded.
    def evict_if_needed
      return unless @store.size >= @capacity

      lru_key = @order.shift
      @store.delete(lru_key)
    end
  end
end
