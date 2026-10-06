require 'core'

# Example usage:
# qaoa = Core::QAOA.new(2, 2, 2, 2)
# gates, measurements = qaoa.generate_circuit([0.5, 0.5, 0.5, 0.5])

# Run unit tests
TestQAOA.run

# Generate quantum circuit
qaoa = Core::QAOA.new(2, 2, 2, 2)
gates, measurements = qaoa.generate_circuit([0.5, 0.5, 0.5, 0.5])

# Output quantum gates and measurements
puts "Gates: #{gates}"
puts "Measurements: #{measurements}"
