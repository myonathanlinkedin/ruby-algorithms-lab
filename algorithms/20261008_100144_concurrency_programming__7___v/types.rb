class Volatile
  # A simple thread-safe wrapper for a value.
  # Provides atomic get, set, and optional increment operations.
  def initialize(initial = nil)
    @mutex = Mutex.new
    @value = initial
  end

  # Atomically reads the current value.
  def get
    @mutex.synchronize { @value }
  end

  # Atomically sets the value.
  def set(new_value)
    @mutex.synchronize { @value = new_value }
  end

  # Atomically increments the value if it responds to +.
  # Returns the new value.
  def increment(delta = 1)
    @mutex.synchronize do
      raise TypeError, "value does not support + operation" unless @value.respond_to?(:+)
      @value = @value + delta
    end
  end
end
