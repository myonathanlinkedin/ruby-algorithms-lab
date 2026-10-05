require_relative 'types'
require 'fileutils'

class LSMTree
  DEFAULT_MEMTABLE_LIMIT = 1000
  DEFAULT_BLOOM_BITS = 8192
  DEFAULT_BLOOM_HASHES = 4
  DEFAULT_COMPACTION_THRESHOLD = 4

  def initialize(options = {})
    @memtable = {} # key => KVPair
    @memtable_limit = options.fetch(:memtable_limit, DEFAULT_MEMTABLE_LIMIT)
    @sstable_dir = options.fetch(:sstable_dir, 'sstables')
    @bloom_bits = options.fetch(:bloom_bits, DEFAULT_BLOOM_BITS)
    @bloom_hashes = options.fetch(:bloom_hashes, DEFAULT_BLOOM_HASHES)
    @compaction_threshold = options.fetch(:compaction_threshold, DEFAULT_COMPACTION_THRESHOLD)

    FileUtils.mkdir_p(@sstable_dir)
    @sstables = [] # Array of SSTableMetadata, newest first
    @sstable_cache = {} # file_path => {key => KVPair}
  end

  # Public API --------------------------------------------------------------

  def put(key, value)
    @memtable[key] = KVPair.new(key, value)
    flush_if_necessary
    self
  end

  def delete(key)
    @memtable[key] = KVPair.new(key, nil) # tombstone
    flush_if_necessary
    self
  end

  def get(key)
    # Check memtable first (most recent)
    if @memtable.key?(key)
      pair = @memtable[key]
      return nil if pair.value.nil? # tombstone
      return pair.value
    end

    # Search SSTables from newest to oldest
    @sstables.each do |meta|
      next unless meta.bloom_filter.maybe_contains?(key)
      next if key < meta.min_key || key > meta.max_key

      table = load_sstable(meta.file_path)
      if table.key?(key)
        pair = table[key]
        return nil if pair.value.nil?
        return pair.value
      end
    end
    nil
  end

  def range_query(start_key, end_key)
    result = {}

    # Gather from memtable
    @memtable.each do |k, pair|
      next if k < start_key || k > end_key
      result[k] = pair unless pair.value.nil?
    end

    # Gather from SSTables (newer overrides older)
    @sstables.each do |meta|
      next unless ranges_overlap?(start_key, end_key, meta.min_key, meta.max_key)

      table = load_sstable(meta.file_path)
      table.each do |k, pair|
        next if k < start_key || k > end_key
        # Respect newer version (skip if already present)
        next if result.key?(k)
        result[k] = pair unless pair.value.nil?
      end
    end

    # Return sorted hash by key
    result.sort.to_h
  end

  # -------------------------------------------------------------------------

  private

  def flush_if_necessary
    if @memtable.size >= @memtable_limit
      flush_memtable
      compact_if_necessary
    end
  end

  def flush_memtable
    return if @memtable.empty?

    timestamp = Time.now.to_f
    sorted_keys = @memtable.keys.sort
    min_key = sorted_keys.first
    max_key = sorted_keys.last
    file_name = "sstable_#{timestamp}.dat"
    file_path = File.join(@sstable_dir, file_name)

    bloom = BloomFilter.new(@bloom_bits, @bloom_hashes)

    File.open(file_path, 'wb') do |f|
      sorted_keys.each do |k|
        pair = @memtable[k]
        Marshal.dump(pair, f)
        bloom.add(k)
      end
    end

    meta = SSTableMetadata.new(
      file_path: file_path,
      bloom_filter: bloom,
      min_key: min_key,
      max_key: max_key,
      timestamp: timestamp
    )
    @sstables.unshift(meta) # newest first
    @memtable.clear
  end

  def compact_if_necessary
    return if @sstables.size < @compaction_threshold

    # Simple compaction: merge the two oldest tables
    oldest = @sstables.pop
    second_oldest = @sstables.pop
    merged = merge_sstables(oldest, second_oldest)
    @sstables.unshift(merged)
  end

  def merge_sstables(meta_a, meta_b)
    table_a = load_sstable(meta_a.file_path)
    table_b = load_sstable(meta_b.file_path)

    merged_hash = {}

    # Insert all entries from older (b) then newer (a) to respect timestamps
    [table_b, table_a].each do |tbl|
      tbl.each do |k, pair|
        merged_hash[k] = pair
      end
    end

    # Remove tombstones
    merged_hash.reject! { |_k, v| v.value.nil? }

    # Write merged SSTable
    timestamp = Time.now.to_f
    sorted_keys = merged_hash.keys.sort
    min_key = sorted_keys.first
    max_key = sorted_keys.last
    file_name = "sstable_#{timestamp}.dat"
    file_path = File.join(@sstable_dir, file_name)

    bloom = BloomFilter.new(@bloom_bits, @bloom_hashes)

    File.open(file_path, 'wb') do |f|
      sorted_keys.each do |k|
        pair = merged_hash[k]
        Marshal.dump(pair, f)
        bloom.add(k)
      end
    end

    # Cleanup old files
    [meta_a.file_path, meta_b.file_path].each { |p| File.delete(p) if File.exist?(p) }
    @sstable_cache.delete(meta_a.file_path)
    @sstable_cache.delete(meta_b.file_path)

    SSTableMetadata.new(
      file_path: file_path,
      bloom_filter: bloom,
      min_key: min_key,
      max_key: max_key,
      timestamp: timestamp
    )
  end

  def load_sstable(path)
    return @sstable_cache[path] if @sstable_cache.key?(path)

    table = {}
    File.open(path, 'rb') do |f|
      while !f.eof?
        pair = Marshal.load(f)
        table[pair.key] = pair
      end
    end
    @sstable_cache[path] = table
    table
  end

  def ranges_overlap?(a_start, a_end, b_start, b_end)
    a_start <= b_end && b_start <= a_end
  end
end
