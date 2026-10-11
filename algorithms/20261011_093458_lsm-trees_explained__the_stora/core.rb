# LSM-Tree core implementation – pure Ruby, no external dependencies.
# Provides an in‑memory MemTable, immutable SSTable runs, and a simple compaction strategy.

class MemTable
  attr_reader :size

  def initialize
    @store = {}          # key => [value, timestamp]
    @size = 0
    @timestamp = 0
  end

  # Insert or update a key. Returns true if a new entry was added.
  def put(key, value)
    @timestamp += 1
    new_entry = @store[key].nil?
    @store[key] = [value, @timestamp]
    @size += 1 if new_entry
    true
  end

  # Mark a key as deleted using a tombstone (nil value).
  def delete(key)
    put(key, nil)
  end

  # Retrieve the latest value for a key, or nil if not present / deleted.
  def get(key)
    entry = @store[key]
    entry ? entry[0] : nil
  end

  # Flush current contents into an immutable SSTable run.
  # Returns an SSTable instance and resets the memtable.
  def flush
    entries = @store.map { |k, (v, ts)| [k, v, ts] }
    entries.sort_by! { |e| e[0] } # sort by key
    sstable = SSTable.new(entries)
    @store.clear
    @size = 0
    sstable
  end

  # Returns true if the memtable reached the capacity limit.
  def full?(capacity)
    @size >= capacity
  end
end

class SSTable
  # Immutable sorted run: array of [key, value, timestamp]
  attr_reader :entries

  def initialize(sorted_entries)
    @entries = sorted_entries.freeze
  end

  # Binary search for a key; returns [value, timestamp] or nil.
  def get(key)
    lo = 0
    hi = @entries.length - 1
    while lo <= hi
      mid = (lo + hi) / 2
      mid_key = @entries[mid][0]
      if mid_key == key
        val, ts = @entries[mid][1], @entries[mid][2]
        return [val, ts]
      elsif mid_key < key
        lo = mid + 1
      else
        hi = mid - 1
      end
    end
    nil
  end
end

class LSMTree
  DEFAULT_MEMTABLE_CAP = 4   # small for demonstration; real systems use MBs
  DEFAULT_RUN_LIMIT    = 4   # trigger compaction when runs exceed this count

  def initialize(memtable_capacity: DEFAULT_MEMTABLE_CAP, run_limit: DEFAULT_RUN_LIMIT)
    @mem = MemTable.new
    @runs = []                # array of SSTable, newest first
    @mem_cap = memtable_capacity
    @run_limit = run_limit
  end

  # Public API --------------------------------------------------------------

  def put(key, value)
    @mem.put(key, value)
    flush_if_needed
    self
  end

  def delete(key)
    @mem.delete(key)
    flush_if_needed
    self
  end

  def get(key)
    # Check memtable first (most recent)
    val = @mem.get(key)
    return val unless val.nil? && @mem.store.key?(key) # explicit tombstone

    # Search runs from newest to oldest
    @runs.each do |run|
      result = run.get(key)
      next unless result
      val, _ts = result
      return val unless val.nil? # nil means tombstone
      return nil
    end
    nil
  end

  # For testing: expose internal structures (read‑only)
  def memtable_size; @mem.size; end
  def run_count; @runs.size; end
  def runs; @runs.map { |r| r.entries.map { |e| e[0..1] } }; end

  # -------------------------------------------------------------------------

  private

  # Flush memtable when capacity exceeded.
  def flush_if_needed
    if @mem.full?(@mem_cap)
      @runs.unshift(@mem.flush) # newest run at front
      compact_if_needed
    end
  end

  # Simple compaction: merge all runs into a single sorted run.
  # Discards older tombstones.
  def compact_if_needed
    return if @runs.size <= @run_limit

    merged = merge_runs(@runs)
    @runs = [SSTable.new(merged)]
  end

  # Merge multiple sorted runs into one sorted array.
  # Keeps the entry with the highest timestamp for each key.
  def merge_runs(runs)
    # Use a min‑heap via Ruby's Array#heapify? Not in stdlib.
    # We'll perform k‑way merge using pointers (efficient enough for small demo).
    pointers = Array.new(runs.size, 0)
    result = []
    last_key = nil

    loop do
      # Find the smallest current key among runs
      min_key = nil
      min_run = nil
      runs.each_with_index do |run, idx|
        ptr = pointers[idx]
        next if ptr >= run.entries.length
        key = run.entries[ptr][0]
        if min_key.nil? || key < min_key
          min_key = key
          min_run = idx
        end
      end
      break unless min_key

      # Gather all entries with this key from all runs
      candidates = []
      runs.each_with_index do |run, idx|
        ptr = pointers[idx]
        next if ptr >= run.entries.length
        if run.entries[ptr][0] == min_key
          candidates << run.entries[ptr]
          pointers[idx] += 1
        end
      end

      # Choose entry with max timestamp (most recent)
      best = candidates.max_by { |e| e[2] }
      # Skip tombstones (value nil) unless they are the only version
      unless best[1].nil?
        result << best
      end
      last_key = min_key
    end
    result
  end
end
end
end
end
