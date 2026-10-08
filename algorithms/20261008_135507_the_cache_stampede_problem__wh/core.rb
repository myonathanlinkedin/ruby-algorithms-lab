class Cache
  # Public: Retrieve a value for +key+ from the cache, computing it with the
  # supplied block if absent or expired. Guarantees that at most one thread
  # computes the value for a given key at a time (dog‑pile protection).
  #
  # key - Any object usable as a Hash key.
  # ttl: Integer - Time‑to‑live in seconds (optional, defaults to cache default).
  #
  # Returns the cached or newly computed value.
  # Raises any exception raised by the computation block.
  def get(key, ttl: nil, &block)
    raise ArgumentError, "block required" unless block_given?

    ttl ||= @default_ttl
    entry = nil

    # Fast read‑only path.
    @store_mutex.synchronize { entry = @store[key] }

    if entry && !entry.expired?
      return entry.value
    end

    # Ensure exclusive computation per key.
    @store_mutex.synchronize do
      entry = @store[key]

      if entry && entry.computing?
        entry.wait_for_value
        raise entry.exception if entry.exception
        return entry.value
      else
        entry ||= CacheEntry.new
        entry.start_computation
        @store[key] = entry
      end
    end

    begin
      value = block.call
      entry.finish_computation(value, ttl)
      value
    rescue => e
      entry.fail_computation(e)
      raise
    end
  end

  # Public: Create a new Cache.
  #
  # default_ttl: Integer - Default TTL in seconds for entries (default: 60).
  def initialize(default_ttl: 60)
    @store = {}
    @store_mutex = Mutex.new
    @default_ttl = default_ttl
  end

  # Internal: Represents a single cache entry.
  class CacheEntry
    attr_reader :value

    def initialize
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @computing = false
      @value = nil
      @expires_at = Time.at(0)
      @exception = nil
    end

    # Returns true if the entry is past its expiration time.
    def expired?
      Time.now >= @expires_at
    end

    # Returns true if a computation is currently in progress.
    def computing?
      @computing
    end

    # Marks the entry as being computed.
    def start_computation
      @mutex.synchronize do
        @computing = true
        @exception = nil
      end
    end

    # Stores the successful result, sets a jittered expiration, and wakes waiters.
    def finish_computation(val, ttl)
      @mutex.synchronize do
        @value = val
        jitter = 0.9 + rand * 0.2          # 90‑110 % of ttl
        @expires_at = Time.now + ttl * jitter
        @computing = false
        @cond.broadcast
      end
    end

    # Stores the raised exception and wakes waiters.
    def fail_computation(exc)
      @mutex.synchronize do
        @exception = exc
        @computing = false
        @cond.broadcast
      end
    end

    # Blocks the caller until the current computation finishes.
    def wait_for_value
      @mutex.synchronize do
        @cond.wait(@mutex) while @computing
      end
    end

    # Returns the exception captured during computation, if any.
    def exception
      @exception
    end
  end
end
