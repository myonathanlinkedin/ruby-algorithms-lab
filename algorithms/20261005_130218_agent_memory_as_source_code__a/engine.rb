# frozen_string_literal: true

require_relative 'types'

module MemoryEngine
  # Core engine exposing a DSL for neuron/synapse definition and ledger tracking.
  class Engine
    attr_reader :neurons, :ledger

    def initialize
      @neurons = {} # name => Neuron
      @ledger = MemoryTypes::Ledger.new
    end

    # DSL entry point: define a neuron.
    # Example: neuron :A do |input| Math.tanh(input) end
    def neuron(name, &activation_block)
      raise ArgumentError, "Neuron #{name} already defined" if @neurons.key?(name)

      neuron = MemoryTypes::Neuron.new(name, activation_block)
      @neurons[name] = neuron
      @ledger.append('create_neuron', name: name)
      neuron
    end

    # DSL entry point: connect two existing neurons.
    # Example: synapse from: :A, to: :B, weight: 0.75
    def synapse(from:, to:, weight:)
      src = @neurons[from] or raise ArgumentError, "Source neuron #{from} not found"
      tgt = @neurons[to]   or raise ArgumentError, "Target neuron #{to} not found"
      syn = src.connect_to(tgt, weight: weight)
      @ledger.append('create_synapse', from: from, to: to, weight: weight)
      syn
    end

    # Retrieve a neuron by name.
    def get_neuron(name)
      @neurons[name] or raise ArgumentError, "Neuron #{name} does not exist"
    end

    # Propagate a signal through a specific synapse.
    def propagate(from:, signal:)
      src = get_neuron(from)
      results = src.outgoing.map { |syn| syn.propagate(signal) }
      @ledger.append('propagate', from: from, signal: signal, results: results)
      results
    end

    # Verify ledger integrity; raises on failure.
    def verify_ledger!
      @ledger.assert_integrity!
    end

    # Export a snapshot of the current network as a Ruby DSL string.
    def export_dsl
      lines = []
      @neurons.each_value do |neuron|
        lines << "neuron :#{neuron.name}"
      end
      @neurons.each_value do |neuron|
        neuron.outgoing.each do |syn|
          lines << "synapse from: :#{syn.source.name}, to: :#{syn.target.name}, weight: #{syn.weight}"
        end
      end
      lines.join("\n")
    end
  end
end
