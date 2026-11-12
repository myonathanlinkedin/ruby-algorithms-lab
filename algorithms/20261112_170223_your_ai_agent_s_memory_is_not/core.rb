# frozen_string_literal: true

# Module encapsulating memory safety utilities.
module MemorySafety
  # Raised when a requested context entry is considered stale.
  class StaleContextError < StandardError; end

  # ContextStore maintains key‑value pairs with versioning and age tracking.
  # It provides deterministic stale detection and optional LRU eviction.
  class ContextStore
    # Public: Create a new store.
    #
    # max_age_seconds - Maximum age (in seconds) before an entry is stale.
    # max_size        - Maximum number of entries; excess triggers LRU eviction.
    #
    # Returns a ContextStore instance.
    def initialize(max_age_seconds: 60, max_size: 1_000)
      @max_age_seconds = max_age_seconds
      @max_size = max_size
      @store = {}          # key => {value:, timestamp:, version:}
      @lru = []            # keys ordered from most recent (front) to least.
    end

    # Public: Store a value under a key.
    #
    # key   - Any object usable as a Hash key.
    # value - The value to store.
    #
    # Returns the stored value.
    def set(key, value)
      entry = @store[key]
      if entry
        entry[:value] = value
        entry[:timestamp] = current_time
        entry[:version] += 1
        move_to_front(key)
      else
        @store[key] = {
          value: value,
          timestamp: current_time,
          version: 1
        }
        @lru.unshift(key)
        evict_if_necessary
      end
      value
    end

    # Public: Retrieve a value if it is fresh.
    #
    # key - The key to look up.
    #
    # Raises StaleContextError if the entry is stale or missing.
    # Returns the stored value otherwise.
    def get(key)
      entry = @store[key]
      raise StaleContextError, "Key #{key.inspect} not found" unless entry
      raise StaleContextError, "Key #{key.inspect} is stale" if stale?(key)

      move_to_front(key)
      entry[:value]
    end

    # Public: Return true if the entry is stale or missing.
    #
    # key - The key to inspect.
    #
    # Returns true if stale or absent, false otherwise.
    def stale?(key)
      entry = @store[key]
      return true unless entry

      age = current_time - entry[:timestamp]
      age > @max_age_seconds
    end

    # Public: Refresh a stale entry using the supplied block.
    #
    # key   - The key to refresh.
    # block - A block that computes a fresh value.
    #
    # If the entry is fresh, returns the existing value.
    # If stale or missing, computes, stores, and returns the new value.
    def refresh(key, &block)
      raise ArgumentError, 'Block required' unless block_given?

      if stale?(key)
        new_value = block.call
        set(key, new_value)
      else
        get(key)
      end
    end

    # Public: Delete a key from the store.
    #
    # key - The key to delete.
    #
    # Returns true if the key existed, false otherwise.
    def delete(key)
      existed = @store.delete(key)
      @lru.delete(key)
      !existed.nil?
    end

    # Public: Number of entries currently stored.
    #
    # Returns an Integer.
    def size
      @store.size
    end

    # Public: Remove all entries.
    #
    # Returns self.
    def clear
      @store.clear
      @lru.clear
      self
    end

    # Public: Retrieve the version number for a key.
    #
    # key - The key to query.
    #
    # Returns Integer version or nil if missing.
    def version(key)
      entry = @store[key]
      entry ? entry[:version] : nil
    end

    private

    # Internal: Current monotonic time in seconds.
    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Internal: Move a key to the front of the LRU list.
    def move_to_front(key)
      @lru.delete(key)
      @lru.unshift(key)
    end

    # Internal: Evict least‑recently‑used entries if size exceeds @max_size.
    def evict_if_necessary
      while @store.size > @max_size
        lru_key = @lru.pop
        @store.delete(lru_key)
      end
    end
  end
end
end
