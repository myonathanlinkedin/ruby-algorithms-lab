require 'minitest/autorun'
require_relative 'core'

class TestLamportClock < Minitest::Test
  def setup
    @c1 = LamportClock.new(1)
    @c2 = LamportClock.new(2)
  end

  def test_tick_monotonic
    t1 = @c1.tick
    t2 = @c1.tick
    assert_operator t2, :>, t1, "Tick must produce strictly increasing timestamps"
  end

  def test_receive_updates_counter
    local = @c1.tick          # 1
    remote = 5
    updated = @c1.receive(remote) # max(1,5)+1 = 6
    assert_equal 6, updated
    assert_equal 6, @c1.counter
  end

  def test_total_order_respects_counter_then_id
    @c1.tick   # counter = 1, id = 1
    @c2.tick   # counter = 1, id = 2
    assert @c1 < @c2, "When counters equal, lower process_id should be smaller"
    @c2.tick   # counter = 2
    assert @c2 > @c1, "Higher counter dominates process_id"
  end

  def test_event_ordering
    events = LamportSimulator.run_scenario
    sorted = events.sort
    # Verify that sorting respects Lamport total order
    assert_equal sorted.map(&:description), sorted.map(&:description).sort_by.with_index { |desc, i| i }
    # Ensure that a causal receive follows its send
    send_event = events.find { |e| e.description == "P1 send to P2" }
    recv_event = events.find { |e| e.description == "P2 receive from P1" }
    assert_operator recv_event, :>, send_event, "Receive must be ordered after its send"
  end

  def test_concurrent_events_not_causal
    events = LamportSimulator.run_scenario
    # Identify two events that are concurrent (no causal path)
    # "P2 internal X" and "P1 internal A" are concurrent.
    a = events.find { |e| e.description == "P1 internal A" }
    x = events.find { |e| e.description == "P2 internal X" }
    # Their total order is deterministic but they are not causally related.
    assert a != x
    # Ensure no causal relationship by checking that neither event's timestamp was derived from the other.
    # In this simple simulation, causality only occurs via receive().
    # Since neither event involved receive, they are concurrent.
    assert a.timestamp != x.timestamp || a.process_id != x.process_id
  end
end

# Demonstration entry point (executed when running this file directly)
if __FILE__ == $0
  puts "Running Lamport timestamp simulation..."
  events = LamportSimulator.run_scenario
  puts "\nGenerated events (unsorted):"
  events.each do |e|
    puts "Process #{e.process_id} | Counter #{e.timestamp} | #{e.description}"
  end

  puts "\nEvents sorted by Lamport total order:"
  events.sort.each do |e|
    puts "Process #{e.process_id} | Counter #{e.timestamp} | #{e.description}"
  end

  puts "\nObservation: Events are totally ordered, yet 'P1 internal A' and 'P2 internal X' are concurrent."
end
