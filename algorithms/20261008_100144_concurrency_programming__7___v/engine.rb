require_relative 'types'

class Counter
  # Counter that uses a Volatile integer internally to guarantee visibility
  # across threads without external synchronization.
  def initialize(initial = 0)
    @counter = Volatile.new(initial)
  end

  # Increment the counter by 1 atomically.
  def increment
    @counter.increment(1)
  end

  # Return the current count atomically.
  def value
    @counter.get
  end
end
