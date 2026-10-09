require 'ostruct'

class BuddySystem
  attr_reader :blocks

  def initialize(block_size)
    @block_size = block_size
    @free_blocks = []
    @used_blocks = []
    @block_map = {}

    (1..(1 << block_size)).each do |i|
      @free_blocks << i
    end
  end

  def allocate
    if @free_blocks.empty?
      raise "No free blocks available"
    end

    block_index = @free_blocks.pop
    block = @block_map[block_index]

    @block_map[block_index] = nil
    @free_blocks.unshift(block_index)

    block
  end

  def deallocate(block)
    @block_map[block] = block_index_from_block(block)
    @free_blocks << block_index_from_block(block)
  end

  private

  def block_index_from_block(block)
    block_index = (block & (block - 1))
    @block_map[block_index] = block
    block_index
  end

  def block_index_from_index(index)
    block_index = (index >> block_size_log2)
    @block_map[block_index] = index
    block_index
  end

  def block_size_log2
    log2(block_size)
  end

  def log2(n)
    return 0 if n < 2
    return 1 + log2(n >> 1)
  end
end
