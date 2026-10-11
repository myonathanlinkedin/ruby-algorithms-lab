require_relative 'core'
require 'minitest/autorun'
require 'benchmark'

class TestDora < Minitest::Test
  def setup
    @d = Dora.new
  end

  def test_initial_state
    assert_equal 0, @d.size
    assert @d.empty?
    assert_raises(IndexError) { @d.pop_front }
    assert_raises(IndexError) { @d.pop_back }
  end

  def test_push_back_and_pop_back
    @d.push_back(1).push_back(2).push_back(3)
    assert_equal 3, @d.size
    assert_equal 3, @d.pop_back
    assert_equal 2, @d.pop_back
    assert_equal 1, @d.pop_back
    assert @d.empty?
  end

  def test_push_front_and_pop_front
    @d.push_front('a').push_front('b').push_front('c')
    assert_equal 3, @d.size
    assert_equal 'c', @d.pop_front
    assert_equal 'b', @d.pop_front
    assert_equal 'a', @d.pop_front
    assert @d.empty?
  end

  def test_mixed_operations
    @d.push_back(10)
    @d.push_front(20)
    @d.push_back(30)
    @d.push_front(40) # queue: 40,20,10,30
    assert_equal [40, 20, 10, 30], @d.to_a
    assert_equal 40, @d.pop_front
    assert_equal 30, @d.pop_back
    assert_equal [20, 10], @d.to_a
  end

  def test_random_access
    5.times { |i| @d.push_back(i * 2) } # [0,2,4,6,8]
    assert_equal 0, @d.get(0)
    assert_equal 8, @d.get(4)
    @d.set(2, 99)
    assert_equal 99, @d.get(2)
    assert_raises(IndexError) { @d.get(5) }
    assert_raises(IndexError) { @d.set(-1, 0) }
  end

  def test_wrap_around_behavior
    # Force internal head/tail to wrap by using small initial capacity
    d = Dora.new(4)
    d.push_back(1).push_back(2).push_back(3) # full
    assert_equal [1,2,3], d.to_a
    d.pop_front   # remove 1, head moves
    d.push_back(4) # tail wraps
    assert_equal [2,3,4], d.to_a
    d.pop_back    # remove 4
    d.pop_front   # remove 2
    d.push_front(5)
    d.push_back(6)
    assert_equal [5,3,6], d.to_a
  end

  def test_growth
    d = Dora.new(2)
    10.times { |i| d.push_back(i) }
    assert_equal 10, d.size
    assert_equal (0..9).to_a, d.to_a
  end

  def test_enumerable
    @d.push_back('x').push_back('y').push_back('z')
    collected = []
    @d.each { |e| collected << e }
    assert_equal %w[x y z], collected
    assert_equal @d.map { |e| e.upcase }, %w[X Y Z]
  end
end

# Simple benchmark demonstrating amortized O(1) push_back
if __FILE__ == $0
  puts "Benchmark: push_back 1_000_000 elements"
  d = Dora.new
  time = Benchmark.realtime { 1_000_000.times { |i| d.push_back(i) } }
  puts "Elapsed: #{time.round(4)} seconds, final size: #{d.size}"
end
