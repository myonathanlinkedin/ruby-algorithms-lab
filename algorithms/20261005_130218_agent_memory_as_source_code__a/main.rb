# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'engine'

class TestMemoryEngine < Minitest::Test
  def setup
    @engine = MemoryEngine::Engine.new
  end

  def test_neuron_creation
    n = @engine.neuron(:A) { |x| x * 2 }
    assert_equal :A, n.name
    assert_in_delta 4, n.activate(2), 1e-9
    assert_equal 1, @engine.ledger.entries.size
    assert_equal 'create_neuron', @engine.ledger.entries.last.operation
  end

  def test_duplicate_neuron_error
    @engine.neuron(:A)
    assert_raises(ArgumentError) { @engine.neuron(:A) }
  end

  def test_synapse_creation_and_propagation
    @engine.neuron(:A) { |x| x + 1 }
    @engine.neuron(:B) { |x| x * 3 }
    syn = @engine.synapse(from: :A, to: :B, weight: 0.5)
    assert_instance_of MemoryTypes::Synapse, syn
    assert_in_delta 4.5, @engine.propagate(from: :A, signal: 2).first, 1e-9
    assert_equal 3, @engine.ledger.entries.size # neuron A, neuron B, synapse
  end

  def test_ledger_integrity
    @engine.neuron(:X)
    @engine.neuron(:Y)
    @engine.synapse(from: :X, to: :Y, weight: 1.0)
    @engine.verify_ledger! # should not raise
    # Tamper with an entry
    entry = @engine.ledger.entries.first
    entry.instance_variable_set(:@hash, 'invalid')
    refute @engine.ledger.valid_chain?
    assert_raises(RuntimeError) { @engine.verify_ledger! }
  end

  def test_export_dsl
    @engine.neuron(:A)
    @engine.neuron(:B)
    @engine.synapse(from: :A, to: :B, weight: 0.42)
    dsl = @engine.export_dsl
    expected = <<~DSL.strip
      neuron :A
      neuron :B
      synapse from: :A, to: :B, weight: 0.42
    DSL
    assert_equal expected, dsl
  end
end

# Demo execution when file is run directly
if __FILE__ == $PROGRAM_NAME
  engine = MemoryEngine::Engine.new
  engine.neuron(:Input) { |x| x }
  engine.neuron(:Hidden) { |x| Math.tanh(x) }
  engine.neuron(:Output) { |x| x }
  engine.synapse from: :Input, to: :Hidden, weight: 0.8
  engine.synapse from: :Hidden, to: :Output, weight: 1.2

  puts "Network DSL representation:"
  puts engine.export_dsl
  puts "\nLedger valid? #{engine.ledger.valid_chain?}"
end
