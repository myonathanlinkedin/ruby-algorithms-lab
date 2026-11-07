# frozen_string_literal: true

# Lamport logical clock implementation.
# Provides deterministic ordering of events in a distributed system
# without relying on physical time.
module Lamport
  # Simple immutable message carrier used by the engine.
  Message = Struct.new(:sender_id, :timestamp, :payload) do
    def to_s
      "Message<#{sender_id}:#{timestamp}>"
    end
  end

  # Logical clock adhering to Lamport's algorithm.
  #
  # Invariants:
  # * @counter is always a non‑negative integer.
  # * After any operation the clock value is monotonically non‑decreasing.
  class Clock
    attr_reader :id, :counter

    # Initialize a new clock.
    #
    # @param id [Object] optional identifier for debugging / tracing.
    # @param start [Integer] initial logical time (default: 0).
    def initialize(id: nil, start: 0)
      raise ArgumentError, 'start must be non‑negative' unless start.is_a?(Integer) && start >= 0

      @id = id
      @counter = start
    end

    # Record an internal event.
    #
    # @return [Integer] the new logical timestamp.
    def tick
      @counter += 1
    end

    # Record a send event.
    #
    # @param payload [Object] optional payload attached to the message.
    # @return [Message] a message carrying the current timestamp.
    def send_event(payload = nil)
      tick
      Message.new(@id, @counter, payload)
    end

    # Record a receive event.
    #
    # @param remote_timestamp [Integer] timestamp received from a peer.
    # @return [Integer] the updated logical timestamp.
    def receive_event(remote_timestamp)
      raise ArgumentError, 'remote_timestamp must be an Integer' unless remote_timestamp.is_a?(Integer)

      @counter = [@counter, remote_timestamp].max + 1
    end

    # Convenience accessor for the current logical time.
    #
    # @return [Integer] current timestamp.
    def now
      @counter
    end
  end
end
