require_relative 'types'
require_relative 'engine'
require 'minitest/autorun'

class TestStack < Minitest::Test
  def setup
    @stack = DataStructures::Stack.new
  end

  def test_initially_empty
    assert @stack.empty?
    assert_equal 0, @stack.size
  end

  def test_push_and_pop
    @stack.push(1)
    @stack.push(2)
    assert_equal 2, @stack.size
    assert_equal 2, @stack.pop
    assert_equal 1, @stack.pop
    assert @stack.empty?
  end

  def test_peek
    @stack.push('a')
    assert_equal 'a', @stack.peek
    assert_equal 1, @stack.size
  end

  def test_underflow
    assert_raises(RuntimeError) { @stack.pop }
    assert_raises(RuntimeError) { @stack.peek }
  end
end

class TestMinHeap < Minitest::Test
  def setup
    @heap = DataStructures::MinHeap.new
  end

  def test_initially_empty
    assert @heap.empty?
    assert_equal 0, @heap.size
  end

  def test_push_and_pop
    [5, 3, 8, 1, 9].each { |x| @heap.push(x) }
    assert_equal 5, @heap.size
    sorted = []
    until @heap.empty?
      sorted << @heap.pop
    end
    assert_equal [1, 3, 5, 8, 9], sorted
  end

  def test_peek
    @heap.push(10)
    assert_equal 10, @heap.peek
    assert_equal 1, @heap.size
  end

  def test_underflow
    assert_raises(RuntimeError) { @heap.pop }
    assert_raises(RuntimeError) { @heap.peek }
  end
end

if __FILE__ == $0
  puts 'Stack demo:'
  stack = DataStructures::Stack.new
  stack.push(10)
  stack.push(20)
  puts "Top: #{stack.peek}"
  puts "Popped: #{stack.pop}"
  puts "Size: #{stack.size}"
  puts 'Heap demo:'
  heap = DataStructures::MinHeap.new
  [4, 2, 7, 1].each { |x| heap.push(x) }
  puts "Min: #{heap.peek}"
  puts "Extracted: #{heap.pop}"
  puts "Size: #{heap.size}"
end
