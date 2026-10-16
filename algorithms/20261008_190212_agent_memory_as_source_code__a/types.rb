# frozen_string_literal: true

require 'digest'
require 'time'

# Simple immutable ledger entry with hash chaining.
class LedgerEntry
  attr_reader :index, :timestamp, :data, :previous_hash, :hash

  def initialize(index:, timestamp:, data:, previous_hash:)
    @index = index
    @timestamp = timestamp.iso8601
    @data = data.freeze
    @previous_hash = previous_hash.freeze
    @hash = compute_hash
  end

  private

  def compute_hash
    payload = "#{@index}|#{@timestamp}|#{@data}|#{@previous_hash}"
    Digest::SHA256.hexdigest(payload)
  end
end

# Represents a neuron in the network.
class Neuron
  attr_reader :id, :outgoing_synapses
  attr_accessor :value

  def initialize(id)
    @id = id.freeze
    @value = 0.0
    @outgoing_synapses = []
  end

  # Attach a synapse that originates from this neuron.
  def add_synapse(synapse)
    @outgoing_synapses << synapse
  end
end

# Represents a directed, weighted connection between two neurons.
class Synapse
  attr_reader :from_neuron, :to_neuron, :weight

  def initialize(from_neuron:, to_neuron:, weight:)
    @from_neuron = from_neuron
    @to_neuron = to_neuron
    @weight = weight.to_f
  end
end
