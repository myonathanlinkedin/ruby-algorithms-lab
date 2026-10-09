# frozen_string_literal: true

require 'test/unit'
require_relative 'core'

# Test suite for OptimisticLinkedList.
class TestOptimisticLinkedList < Test::Unit::TestCase
  def test_sequential_operations
    list = OptimisticLinkedList.new
    assert_equal([], list.to_a)

    list.insert(10, 0)
    list.insert(20, 1)
    list.insert(15, 1) # list: 10,15,20
    assert_equal([10, 15, 20], list.to_a)

    assert_equal(15, list.get(1))
    assert_equal(20, list.get(2))
    assert_nil(list.get(3))

    removed = list.delete(1) # remove 15
    assert_equal(15, removed)
    assert_equal([10, 20], list.to_a)

    assert_raise(IndexError) { list.get(-1) }
    assert_raise(IndexError) { list.insert(30, 5) }
    assert_raise(IndexError) { list.delete(5) }
  end

  def test_concurrent_reads
    list = OptimisticLinkedList.new
    100.times { |i| list.insert(i, i) }

    read_results = Queue.new
    readers = 10.times.map do
      Thread.new do
        1000.times do
          idx = rand(0...list.size)
          val = list.get(idx)
          read_results << [idx, val]
        end
      end
    end

    readers.each(&:join)

    # Verify that every read returned the expected value.
    until read_results.empty?
      idx, val = read_results.pop
      assert_equal(idx, val)
    end
  end

  def test_concurrent_writes_and_reads
    list = OptimisticLinkedList.new
    50.times { |i| list.insert(i, i) }

    writer = Thread.new do
      200.times do |i|
        idx = rand(0..list.size)
        list.insert(1000 + i, idx)
        # Occasionally delete a random element (if any).
        if list.size > 0 && rand < 0.3
          del_idx = rand(0...list.size)
          list.delete(del_idx)
        end
      end
    end

    readers = 5.times.map do
      Thread.new do
        500.times do
          idx = rand(0...list.size)
          list.get(idx) # value is not asserted; we only ensure no exceptions.
        end
      end
    end

    writer.join
    readers.each(&:join)

    # After all operations, verify internal consistency:
    # No nil values and size matches array length.
    arr = list.to_a
    assert_equal(arr.size, list.size)
    assert(arr.none?(&:nil?))
  end

  def test_stress_under_contention
    list = OptimisticLinkedList.new
    threads = []

    8.times do |t|
      threads << Thread.new do
        1000.times do
          op = rand(3)
          case op
          when 0 # insert at random position
            idx = rand(0..list.size)
            list.insert(t, idx)
          when 1 # delete if not empty
            if list.size > 0
              idx = rand(0...list.size)
              list.delete(idx)
            end
          when 2 # read
            if list.size > 0
              idx = rand(0...list.size)
              list.get(idx)
            end
          end
        end
      end
    end

    threads.each(&:join)

    # Consistency checks after heavy contention.
    arr = list.to_a
    assert_equal(arr.size, list.size)
    assert(arr.none?(&:nil?))
  end
end

# Entry point for manual execution.
if __FILE__ == $PROGRAM_NAME
  puts 'Running OptimisticLinkedList self‑test...'
  Test::Unit::AutoRunner.run
end
