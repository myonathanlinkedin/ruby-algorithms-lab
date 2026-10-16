# frozen_string_literal: true

require_relative 'types'

# Core ledger that stores immutable entries with hash chaining.
class Ledger
  attr_reader :entries

  def initialize
    @entries = []
    # Genesis entry
    add_entry('Genesis')
  end

  # Append a new entry with supplied data.
  def add_entry(data)
    index = @entries.size
    previous_hash = @entries.empty? ? '0' * 64 : @entries.last.hash
    entry = LedgerEntry.new(
      index: index,
      timestamp: Time.now.utc,
      data: data,
      previous_hash: previous_hash
    )
    @entries << entry
    entry
  end

  # Verify the entire chain integrity.
  def valid?
    @entries.each_cons(2).all? do |prev, cur|
      cur.previous_hash == prev.hash && cur.hash == cur.send(:compute_hash)
    end
  end

  # Expose the hash of the latest entry.
  def latest_hash
    @entries.last.hash
  end
end

# Neural network that manages neurons, synapses and records actions in a ledger.
class NeuralNetwork
  attr_reader :neurons, :synapses, :ledger

  def initialize
    @neurons = {}          # id => Neuron
    @synapses = []         # Array of Synapse
    @ledger = Ledger.new
    @next_id = 0
  end

  # Create a new neuron and record the event.
  def add_neuron
    nid = "N#{@next_id}"
    @next_id += 1
    neuron = Neuron.new(nid)
    @neurons[nid] = neuron
    @ledger.add_entry("AddNeuron:#{nid}")
    neuron
  end

  # Connect two existing neurons with a weighted synapse.
  # Raises ArgumentError if ids are unknown.
  def connect(from_id, to_id, weight)
    from = @neurons.fetch(from_id) { raise ArgumentError, "Unknown neuron #{from_id}" }
    to   = @neurons.fetch(to_id)   { raise ArgumentError, "Unknown neuron #{to_id}" }
    synapse = Synapse.new(from_neuron: from, to_neuron: to, weight: weight)
    @synapses << synapse
    from.add_synapse(synapse)
    @ledger.add_entry("Connect:#{from_id}->#{to_id}@#{weight}")
    synapse
  end

  # Fire a neuron with a given stimulus value.
  # Propagation is a single synchronous step.
  def fire_neuron(neuron_id, stimulus)
    neuron = @neurons.fetch(neuron_id) { raise ArgumentError, "Unknown neuron #{neuron_id}" }
    neuron.value = stimulus.to_f
    @ledger.add_entry("Fire:#{neuron_id}=#{stimulus}")

    # Propagate to downstream neurons.
    neuron.outgoing_synapses.each do |syn|
      delta = neuron.value * syn.weight
      syn.to_neuron.value += delta
      @ledger.add_entry("Propagate:#{neuron.id}->#{syn.to_neuron.id}+#{delta}")
    end
    neuron.value
  end

  # Reset all neuron values to zero.
  def reset!
    @neurons.each_value { |n| n.value = 0.0 }
    @ledger.add_entry('ResetNetwork')
    self
  end
end
