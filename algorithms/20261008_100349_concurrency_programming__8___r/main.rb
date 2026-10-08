require 'minitest/autorun'
require_relative 'core'

class ReadWriteLockTest < Minitest::Test
  def setup
    @rw = ReadWriteLock.new
  end

  def test_multiple_readers_can_enter_concurrently
    start_times = Queue.new
    finish_times = Queue.new
    threads = 5.times.map do
      Thread.new do
        @rw.read do
          start_times << Time.now
          sleep 0.1
          finish_times << Time.now
        end
      end
    end
    threads.each(&:join)

    starts = []
    finishes = []
    5.times { starts << start_times.pop }
    5.times { finishes << finish_times.pop }

    earliest_start = starts.min
    latest_finish = finishes.max
    duration = latest_finish - earliest_start

    # If readers truly overlapped, total duration should be close to the sleep time,
    # not 5 * sleep time.
    assert_in_delta 0.1, duration, 0.05
  end

  def test_writer_excludes_readers_and_other_writers
    order = Queue.new

    reader = Thread.new do
      @rw.read do
        order << :reader_start
        sleep 0.2
        order << :reader_end
      end
    end

    # Ensure reader acquires lock first
    sleep 0.05

    writer = Thread.new do
      @rw.write do
        order << :writer_start
        sleep 0.1
        order << :writer_end
      end
    end

    reader.join
    writer.join

    seq = []
    4.times { seq << order.pop }
    assert_equal [:reader_start, :reader_end, :writer_start, :writer_end], seq
  end

  def test_writer_priority_blocks_new_readers
    order = Queue.new

    # Writer arrives first and waits for current readers to finish
    writer = Thread.new do
      @rw.write do
        order << :writer_start
        sleep 0.1
        order << :writer_end
      end
    end

    # Give writer a moment to register its intent
    sleep 0.02

    # New reader that arrives after writer is waiting
    reader = Thread.new do
      @rw.read do
        order << :reader_start
        sleep 0.05
        order << :reader_end
      end
    end

    writer.join
    reader.join

    seq = []
    4.times { seq << order.pop }
    # Reader must start after writer finishes due to writer‑priority policy
    assert_equal [:writer_start, :writer_end, :reader_start, :reader_end], seq
  end

  def test_block_forms_work_as_expected
    counter = 0
    @rw.read { counter += 1 }
    assert_equal 1, counter

    @rw.write { counter *= 2 }
    assert_equal 2, counter
  end
end

# Simple benchmark demonstrating throughput under mixed load
if __FILE__ == $0
  rw = ReadWriteLock.new
  iterations = 100_000
  readers = 4
  writers = 2

  start = Time.now

  reader_threads = readers.times.map do
    Thread.new do
      iterations.times { rw.read { } }
    end
  end

  writer_threads = writers.times.map do
    Thread.new do
      iterations.times { rw.write { } }
    end
  end

  (reader_threads + writer_threads).each(&:join)

  elapsed = Time.now - start
  puts "Performed #{(readers + writers) * iterations} lock operations in #{elapsed.round(3)} seconds"
end
