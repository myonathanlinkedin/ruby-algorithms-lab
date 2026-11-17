# frozen_string_literal: true

module Lamport
  # Logical clock implementing Lamport timestamps.
  class Clock
    attr_reader :counter, :process_id

    # Initialize a clock. +process_id+ is optional and used only for debugging.
    def initialize(process_id = nil)
      @process_id = process_id
      @counter = 0
    end

    # Internal tick: increment the logical counter.
    def tick
      @counter += 1
    end

    # Record a local event. Equivalent to +tick+.
    def event
      tick
    end

    # Record a send event. Increments the counter and returns the timestamp.
    def send_event
      tick
      timestamp
    end

    # Record a receive event from a remote timestamp.
    # The new counter becomes max(local, remote) + 1.
    def receive_event(remote_timestamp)
      @counter = [@counter, remote_timestamp].max + 1
    end

    # Current timestamp value.
    def timestamp
      @counter
    end

    def to_s
      "Clock#{process_id ? "(#{process_id})" : ''}:#{counter}"
    end
  end

  # Simple immutable message carrying a Lamport timestamp.
  class Message
    attr_reader :sender_id, :timestamp, :payload

    def initialize(sender_id, timestamp, payload = nil)
      @sender_id = sender_id
      @timestamp = timestamp
      @payload = payload
    end

    def to_s
      "Message from #{sender_id} @#{timestamp}"
    end
  end
end
