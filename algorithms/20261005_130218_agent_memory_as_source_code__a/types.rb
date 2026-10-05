# frozen_string_literal: true

require 'digest'
require 'time'

module MemoryTypes
  # Represents a single neuron in the network.
  class Neuron
    attr_reader :name, :activation_proc, :incoming, :outgoing

    def initialize(name, activation_proc = nil)
      @name = name.to_sym
      @activation_proc = activation_proc || proc { |x| x } # identity by default
      @incoming = [] # Array of Synapse objects
      @outgoing = [] # Array of Synapse objects
      freeze
    end

    # Compute activation given an input value.
    def activate(input)
      @activation_proc.call(input)
    end

    # Connect this neuron to another via a synapse.
    def connect_to(target_neuron, weight:)
      synapse = Synapse.new(self, target_neuron, weight)
      @outgoing << synapse
      target_neuron.incoming << synapse
      synapse
    end
  end

  # Represents a directed weighted connection between two neurons.
  class Synapse
    attr_reader :source, :target, :weight

    def initialize(source_neuron, target_neuron, weight)
      @source = source_neuron
      @target = target_neuron
      @weight = weight.to_f
      freeze
    end

    # Propagate a signal from source to target.
    def propagate(signal)
      weighted = signal * @weight
      @target.activate(weighted)
    end
  end

  # Immutable ledger entry that participates in a hash‑chained ledger.
  class LedgerEntry
    attr_reader :index, :timestamp, :operation, :payload, :previous_hash, :hash

    def initialize(index:, operation:, payload:, previous_hash:)
      @index = index
      @timestamp = Time.now.utc.iso8601(9)
      @operation = operation.freeze
      @payload = payload.freeze
      @previous_hash = previous_hash.freeze
      @hash = compute_hash
      freeze
    end

    # Verify that the stored hash matches the recomputed hash.
    def valid_hash?
      @hash == compute_hash
    end

    private

    def compute_hash
      Digest::SHA256.hexdigest(
        [
          @index,
          @timestamp,
          @operation,
          @payload.inspect,
          @previous_hash
        ].join('|')
      )
    end
  end

  # Ledger maintains an ordered, hash‑chained list of LedgerEntry objects.
  class Ledger
    attr_reader :entries

    def initialize
      @entries = []
    end

    # Append a new entry; automatically links the hash chain.
    def append(operation, payload = {})
      previous_hash = @entries.empty? ? '0' * 64 : @entries.last.hash
      entry = LedgerEntry.new(
        index: @entries.size,
        operation: operation,
        payload: payload,
        previous_hash: previous_hash
      )
      @entries << entry
      entry
    end

    # Verify the integrity of the entire chain.
    def valid_chain?
      @entries.each_with_index.all? do |entry, idx|
        expected_prev = idx.zero? ? '0' * 64 : @entries[idx - 1].hash
        entry.previous_hash == expected_prev && entry.valid_hash?
      end
    end

    # Tamper detection helper – raises if chain is invalid.
    def assert_integrity!
      raise 'Ledger integrity compromised' unless valid_chain?
    end
  end
end
