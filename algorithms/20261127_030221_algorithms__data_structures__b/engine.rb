module DataStructures
  class Stack
    def push(item)
      @items << item
    end

    def pop
      raise 'StackUnderflow' if @items.empty?
      @items.pop
    end

    def peek
      raise 'StackUnderflow' if @items.empty?
      @items.last
    end

    def empty?
      @items.empty?
    end

    def size
      @items.size
    end
  end

  class MinHeap
    def push(item)
      @items << item
      sift_up(@items.size - 1)
    end

    def pop
      raise 'HeapUnderflow' if @items.empty?
      min = @items.first
      last = @items.pop
      unless @items.empty?
        @items[0] = last
        sift_down(0)
      end
      min
    end

    def peek
      raise 'HeapUnderflow' if @items.empty?
      @items.first
    end

    def empty?
      @items.empty?
    end

    def size
      @items.size
    end

    private

    def sift_up(index)
      while index > 0
        parent = (index - 1) / 2
        break if @items[parent] <= @items[index]
        @items[parent], @items[index] = @items[index], @items[parent]
        index = parent
      end
    end

    def sift_down(index)
      size = @items.size
      loop do
        left = 2 * index + 1
        right = 2 * index + 2
        smallest = index
        smallest = left if left < size && @items[left] < @items[smallest]
        smallest = right if right < size && @items[right] < @items[smallest]
        break if smallest == index
        @items[smallest], @items[index] = @items[index], @items[smallest]
        index = smallest
      end
    end
  end
end
