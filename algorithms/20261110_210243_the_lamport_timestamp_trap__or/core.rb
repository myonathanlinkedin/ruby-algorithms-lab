class LamportClock
  attr_reader :process_id, :counter

  # Initialize a Lamport clock for a given process identifier.
  # The counter starts at 0.
  def initialize(process_id)
    @process_id = process_id
    @counter = 0
  end

  # Increment the local counter to represent an internal event.
  # Returns the new timestamp as an integer.
  def tick
    @counter += 1
    @counter
  end

  # Incorporate a timestamp received from another process.
  # The local counter becomes max(local, remote) + 1.
  # Returns the updated local timestamp.
  def receive(remote_timestamp)
    @counter = [@counter, remote_timestamp].max + 1
    @counter
  end

  # Return a composite timestamp used for total ordering.
  # The pair [counter, process_id] respects Lamport's total order:
  # first compare counters, then break ties with process_id.
  def timestamp
    [@counter, @process_id]
  end

  # Compare this clock's timestamp with another's.
  # Returns -1 if self < other, 0 if equal, 1 if self > other.
  def compare(other)
    c1, p1 = timestamp
    c2, p2 = other.timestamp
    return -1 if c1 < c2
    return 1  if c1 > c2
    return -1 if p1 < p2
    return 1  if p1 > p2
    0
  end

  # Convenience operator overloads for sorting.
  def <=>(other)
    compare(other)
  end

  def ==(other)
    compare(other).zero?
  end
end

# Simple immutable event carrying a Lamport timestamp.
class Event
  attr_reader :process_id, :timestamp, :description

  # +clock+ is a LamportClock that has already been ticked or received.
  def initialize(process_id, timestamp, description = nil)
    @process_id = process_id
    @timestamp = timestamp # integer counter value
    @description = description
  end

  # Return the composite timestamp used for total ordering.
  def composite_timestamp
    [@timestamp, @process_id]
  end

  # Comparison based on Lamport's total order.
  def <=>(other)
    c1, p1 = composite_timestamp
    c2, p2 = other.composite_timestamp
    return -1 if c1 < c2
    return 1  if c1 > c2
    return -1 if p1 < p2
    return 1  if p1 > p2
    0
  end

  def ==(other)
    compare(other).zero?
  end
end

# Utility module to simulate a minimal distributed system.
module LamportSimulator
  # Simulate two processes generating events and exchanging messages.
  # Returns an array of all generated Event objects.
  def self.run_scenario
    p1 = LamportClock.new(1)
    p2 = LamportClock.new(2)

    events = []

    # Process 1 internal event
    events << Event.new(p1.process_id, p1.tick, "P1 internal A")

    # Process 2 internal event
    events << Event.new(p2.process_id, p2.tick, "P2 internal X")

    # Process 1 sends a message to Process 2 (causal)
    send_ts = p1.tick
    events << Event.new(p1.process_id, send_ts, "P1 send to P2")

    # Process 2 receives the message
    recv_ts = p2.receive(send_ts)
    events << Event.new(p2.process_id, recv_ts, "P2 receive from P1")

    # Process 2 internal event after receive
    events << Event.new(p2.process_id, p2.tick, "P2 internal Y")

    # Process 1 internal event concurrent with P2's last event
    events << Event.new(p1.process_id, p1.tick, "P1 internal B")

    events
  end
end
