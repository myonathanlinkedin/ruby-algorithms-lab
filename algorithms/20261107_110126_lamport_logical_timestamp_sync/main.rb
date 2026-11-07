# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'core'

# Unit‑test suite for the Lamport logical timestamp engine.
class TestLamportClock < Minitest::Test
  def setup
    @clock_a = Lamport::Clock.new(id: :A)
    @clock_b = Lamport::Clock.new(id: :B)
  end

  def test_initial_state
    assert_equal 0, @clock_a.now
    assert_equal 0, @clock_b.now
  end

  def test_tick_monotonicity
    5.times { @clock_a.tick }
    assert_equal 5, @clock_a.now
    @clock_a.tick
    assert_equal 6, @clock_a.now
  end

  def test_send_event_increments
    msg = @clock_a.send_event('hello')
    assert_instance_of Lamport::Message, msg
    assert_equal :A, msg.sender_id
    assert_equal 'hello', msg.payload
    assert_equal 1, msg.timestamp
    assert_equal 1, @clock_a.now
  end

  def test_receive_event_higher_remote
    # A sends a message at t=1
    msg = @clock_a.send_event
    # B receives it; its clock should become max(0,1)+1 = 2
    @clock_b.receive_event(msg.timestamp)
    assert_equal 2, @clock_b.now
  end

  def test_receive_event_lower_remote
    # B performs two internal ticks first
    2.times { @clock_b.tick } # B now at 2
    # A sends at t=1
    msg = @clock_a.send_event
    # B receives; max(2,1)+1 = 3
    @clock_b.receive_event(msg.timestamp)
    assert_equal 3, @clock_b.now
  end

  def test_causal_order_preserved
    # A -> B -> C chain
    clock_c = Lamport::Clock.new(id: :C)

    msg_ab = @clock_a.send_event
    @clock_b.receive_event(msg_ab.timestamp)
    msg_bc = @clock_b.send_event
    clock_c.receive_event(msg_bc.timestamp)

    assert @clock_a.now < msg_ab.timestamp
    assert msg_ab.timestamp < @clock_b.now
    assert @clock_b.now < msg_bc.timestamp
    assert msg_bc.timestamp < clock_c.now
  end

  def test_multiple_interactions
    # Simulate a small network of three clocks exchanging messages.
    clock_c = Lamport::Clock.new(id: :C)

    # Round 1
    m1 = @clock_a.send_event
    @clock_b.receive_event(m1.timestamp)
    m2 = @clock_b.send_event
    @clock_c.receive_event(m2.timestamp)

    # Round 2
    m3 = @clock_c.send_event
    @clock_a.receive_event(m3.timestamp)

    # Verify monotonicity across all clocks
    timestamps = [@clock_a.now, @clock_b.now, @clock_c.now]
    assert timestamps.each_cons(2).all? { |x, y| x <= y } ||
           timestamps.each_cons(2).all? { |x, y| x >= y },
           'All clocks should be comparable after deterministic exchanges'
  end
end

# Simple benchmark demonstrating O(1) per operation cost.
if __FILE__ == $0 && ENV['BENCH']
  require 'benchmark'

  ITER = 10_000_000
  clock = Lamport::Clock.new(id: :Bench)

  puts Benchmark.measure {
    ITER.times { clock.tick }
  }
end

# Entry point for running the test suite when executed directly.
if __FILE__ == $0 && !ENV['BENCH']
  Minitest.run
end
