# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'engine'

class TestNeuralNetwork < Minitest::Test
  def setup
    @net = NeuralNetwork.new
  end

  def test_neuron_creation_and_ledger
    n1 = @net.add_neuron
    n2 = @net.add_neuron
    assert_equal 'N0', n1.id
    assert_equal 'N1', n2.id
    assert_includes @net.neurons.keys, 'N0'
    assert_includes @net.neurons.keys, 'N1'
    # Ledger should have genesis + 2 add entries
    assert_equal 3, @net.ledger.entries.size
    assert @net.ledger.valid?
  end

  def test_synapse_connection_and_propagation
    a = @net.add_neuron
    b = @net.add_neuron
    @net.connect(a.id, b.id, 0.5)
    assert_equal 1, @net.synapses.size
    assert_equal 1, a.outgoing_synapses.size
    assert_equal 0, b.outgoing_synapses.size

    @net.fire_neuron(a.id, 2.0)
    # a receives stimulus, b receives weighted propagation
    assert_in_delta 2.0, a.value, 1e-9
    assert_in_delta 1.0, b.value, 1e-9
    # Ledger entries: genesis, add a, add b, connect, fire, propagate
    assert_equal 6, @net.ledger.entries.size
    assert @net.ledger.valid?
  end

  def test_multiple_layers_propagation
    n0 = @net.add_neuron
    n1 = @net.add_neuron
    n2 = @net.add_neuron
    @net.connect(n0.id, n1.id, 0.3)
    @net.connect(n1.id, n2.id, 0.4)

    @net.fire_neuron(n0.id, 10.0)
    # First layer
    assert_in_delta 10.0, n0.value, 1e-9
    assert_in_delta 3.0, n1.value, 1e-9
    # Second layer does NOT receive second‑order propagation in a single step
    assert_in_delta 0.0, n2.value, 1e-9

    # Manually trigger second step
    @net.fire_neuron(n1.id, n1.value)
    assert_in_delta 3.0, n1.value, 1e-9
    assert_in_delta 1.2, n2.value, 1e-9
    assert @net.ledger.valid?
  end

  def test_ledger_tamper_detection
    n = @net.add_neuron
    @net.fire_neuron(n.id, 5)
    original_hash = @net.ledger.latest_hash

    # Tamper with an entry directly (simulating corruption)
    @net.ledger.entries[2].instance_variable_set(:@data, 'Tampered')
    refute @net.ledger.valid?, 'Ledger should be invalid after tampering'
    refute_equal original_hash, @net.ledger.latest_hash
  end

  def test_reset_network
    a = @net.add_neuron
    b = @net.add_neuron
    @net.connect(a.id, b.id, 1.0)
    @net.fire_neuron(a.id, 7)
    @net.reset!
    assert_in_delta 0.0, a.value, 1e-9
    assert_in_delta 0.0, b.value, 1e-9
    assert @net.ledger.valid?
    # Ledger now contains reset entry
    assert_match /ResetNetwork/, @net.ledger.entries.last.data
  end
end

# Demonstration script (executed when file is run directly)
if __FILE__ == $PROGRAM_NAME
  puts '--- Demo: Simple Neural Network with Ledger ---'
  net = NeuralNetwork.new
  n_input = net.add_neuron
  n_hidden = net.add_neuron
  n_output = net.add_neuron

  net.connect(n_input.id, n_hidden.id, 0.6)
  net.connect(n_hidden.id, n_output.id, 0.9)

  puts "Firing input neuron #{n_input.id} with stimulus 5.0"
  net.fire_neuron(n_input.id, 5.0)

  puts "Values after first propagation:"
  net.neurons.each_value { |n| puts "  #{n.id}: #{n.value}" }

  puts "\nFiring hidden neuron to propagate to output"
  net.fire_neuron(n_hidden.id, n_hidden.value)

  puts "Values after second propagation:"
  net.neurons.each_value { |n| puts "  #{n.id}: #{n.value}" }

  puts "\nLedger entries (hash‑chained):"
  net.ledger.entries.each do |e|
    puts "##{e.index} [#{e.timestamp}] #{e.data} | hash=#{e.hash}"
  end

  puts "\nLedger integrity: #{net.ledger.valid? ? 'VALID' : 'INVALID'}"
end
