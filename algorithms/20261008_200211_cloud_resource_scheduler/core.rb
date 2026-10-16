class NetworkStackHistory
  Entry = Struct.new(:timestamp, :components)

  def initialize
    @entries = []
  end

  # Add a snapshot of the network stack at a given Time.
  # components should be an Array of Strings describing stack layers.
  def add_entry(timestamp, components)
    raise ArgumentError, "timestamp must be a Time" unless timestamp.is_a?(Time)
    raise ArgumentError, "components must be an Array" unless components.is_a?(Array)

    entry = Entry.new(timestamp, components.map(&:to_s))
    idx = insertion_index(timestamp)
    if idx < @entries.size && @entries[idx].timestamp == timestamp
      @entries[idx] = entry # replace existing entry with same timestamp
    else
      @entries.insert(idx, entry)
    end
    self
  end

  # Return the components of the stack as of the given time.
  # If no entry exists before the time, returns an empty array.
  def state_at(query_time)
    raise ArgumentError, "query_time must be a Time" unless query_time.is_a?(Time)
    idx = last_leq_index(query_time)
    idx ? @entries[idx].components.dup : []
  end

  # Return the most recent snapshot (or empty array if none).
  def current_state
    @entries.empty? ? [] : @entries.last.components.dup
  end

  # List all entries in chronological order.
  def entries
    @entries.map { |e| Entry.new(e.timestamp, e.components.dup) }
  end

  private

  # Binary search for the index where a timestamp should be inserted.
  def insertion_index(timestamp)
    low = 0
    high = @entries.size
    while low < high
      mid = (low + high) / 2
      if @entries[mid].timestamp < timestamp
        low = mid + 1
      else
        high = mid
      end
    end
    low
  end

  # Binary search for the index of the last entry <= query_time.
  def last_leq_index(query_time)
    low = 0
    high = @entries.size - 1
    result = nil
    while low <= high
      mid = (low + high) / 2
      if @entries[mid].timestamp <= query_time
        result = mid
        low = mid + 1
      else
        high = mid - 1
      end
    end
    result
  end
end
