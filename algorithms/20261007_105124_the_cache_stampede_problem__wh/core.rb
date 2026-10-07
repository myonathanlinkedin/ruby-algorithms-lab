class CacheStampede
  def initialize
    @cache = {}
    @locks = {}
    @global_mutex = Mutex.new
  end

  def get(key)
    return @cache[key] if @cache.key?(key)

    lock, cond, loading = nil
    @global_mutex.synchronize do
      @locks[key] ||= [Mutex.new, ConditionVariable.new, false]
      lock, cond, loading = @locks[key]
    end

    lock.synchronize do
      return @cache[key] if @cache.key?(key)

      if loading
        cond.wait(lock)
        return @cache[key]
      else
        @locks[key][2] = true
      end
    end

    value = yield

    lock.synchronize do
      @cache[key] = value
      @locks[key][2] = false
      cond.broadcast
    end

    value
  end

  def clear
    @global_mutex.synchronize { @cache.clear }
  end

  def size
    @cache.size
  end
end
