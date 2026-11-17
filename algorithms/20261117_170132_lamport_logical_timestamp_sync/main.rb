# frozen_string_literal: true

require_relative 'core'
require 'test/unit'

class TestLamportClock < Test::Unit::TestCase
  def test_initial_state
    clock = Lamport::Clock.new('A')
    assert_equal(0, clock.counter)
    assert_equal('A', clock.process_id)
  end

  def test_tick_and_event
    clock = Lamport::Clock.new
    clock.tick
    assert_equal(1, clock.counter)
    clock.event
    assert_equal(2, clock.counter)
  end

  def test_send_event
    clock = Lamport::Clock.new('Sender')
    ts = clock.send_event
    assert_equal(1, ts)
    assert_equal(1, clock.counter)
  end

  def test_receive_event
    receiver = Lamport::Clock.new('R')
    sender = Lamport::Clock.new('S')
    sender_ts = sender.send_event   # => 1
    receiver.receive_event(sender_ts)
    assert_equal(2, receiver.counter)
    # Receiving a lower timestamp should still increment.
    receiver.receive_event(0)
    assert_equal(3, receiver.counter)
  end

  def test_causal_ordering_between_two_processes
    p1 = Lamport::Clock.new('P1')
    p2 = Lamport::Clock.new('P2')

    # P1 sends a message.
    ts1 = p1.send_event               # P1 counter = 1
    msg = Lamport::Message.new('P1', ts1, 'hello')

    # P2 receives the message.
    p2.receive_event(msg.timestamp)  # P2 counter = max(0,1)+1 = 2
    assert_equal(2, p2.counter)

    # P2 replies.
    ts2 = p2.send_event               # P2 counter = 3
    reply = Lamport::Message.new('P2', ts2, 'ack')

    # P1 receives reply.
    p1.receive_event(reply.timestamp) # P1 counter = max(1,3)+1 = 4
    assert_equal(4, p1.counter)

    # Verify that timestamps respect causality:
    assert(ts1 < ts2, 'Send timestamp should be less than reply timestamp')
    assert(p1.counter > p2.counter, 'Final counters reflect total order')
  end

  def test_multiple_concurrent_events
    clock = Lamport::Clock.new
    5.times { clock.event }
    assert_equal(5, clock.counter)
    # Simulate receiving a far future timestamp.
    clock.receive_event(20)
    assert_equal(21, clock.counter)
  end
end

# Demonstration when the file is executed directly.
if __FILE__ == $0
  puts 'Running Lamport logical clock demonstration...'
  a = Lamport::Clock.new('A')
  b = Lamport::Clock.new('B')

  puts a.to_s
  puts b.to_s

  # A sends a message.
  ts_a = a.send_event
  msg = Lamport::Message.new('A', ts_a, 'data')
  puts "A sends: #{msg}"

  # B receives it.
  b.receive_event(msg.timestamp)
  puts b.to_s

  # B replies.
  ts_b = b.send_event
  reply = Lamport::Message.new('B', ts_b, 'ack')
  puts "B replies: #{reply}"

  # A receives reply.
  a.receive_event(reply.timestamp)
  puts a.to_s
end
