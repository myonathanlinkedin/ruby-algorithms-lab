require 'lsm_tree'

module LSMTreeEngine
  class LSMTreeEngine
    def initialize(mem_table_size, sstable_size)
      @mem_table_size = mem_table_size
      @sstable_size = sstable_size
      @mem_table = LSMTree::MemTable.new
      @sstables = {}
    end

    def add(key, value)
      @mem_table.put(key, value)
      sstable_path = generate_sstable_path(key)
      @sstables[key] = LSMTree::SSTable.new(sstable_path)
    end

    def get(key)
      value = @mem_table.get(key)
      sstable_path = generate_sstable_path(key)
      sstable = @sstables[key]
      value = sstable.get(key) if sstable
      value
    end

    def remove(key)
      @mem_table.delete(key)
      sstable_path = generate_sstable_path(key)
      sstable = @sstables[key]
      @sstables.delete(key)
      sstable.delete(key) if sstable
    end

    private

    def generate_sstable_path(key)
      "#{key}.sstable"
    end
end
end
