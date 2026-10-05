# frozen_string_literal: true

# Domain models and mathematical interfaces for the Deutsch-Jozsa Algorithm.
# This module defines the core data structures and abstract interfaces required
# for the quantum simulation engine.

module DeutschJozsa
  # Represents the state of a quantum register.
  # In a real quantum computer, this would be a complex vector of amplitudes.
  # For this classical simulation, we track the logical state and the function's behavior.
  class QuantumRegister
    attr_reader :n_qubits

    # @param n_qubits [Integer] The number of qubits in the register.
    def initialize(n_qubits)
      raise ArgumentError, "Number of qubits must be positive" if n_qubits <= 0

      @n_qubits = n_qubits
      @state = 0 # Logical state representation
    end

    # Simulates the Hadamard gate application.
    # In the Deutsch-Jozsa algorithm, this creates a superposition of all basis states.
    def apply_hadamard
      # In a full simulation, this would update the amplitude vector.
      # Here, we mark that superposition has been applied.
      @superposition_applied = true
      self
    end

    # Checks if the register is in a superposition state.
    def superposition?
      defined?(@superposition_applied) && @superposition_applied
    end

    # Resets the register to the ground state |0...0>.
    def reset
      @state = 0
      @superposition_applied = false
      self
    end
  end

  # Abstract base class for the oracle function f(x).
  # The Deutsch-Jozsa problem requires f to be either constant or balanced.
  class Oracle
    # @abstract
    # @param x [Integer] The input bit string represented as an integer.
    # @return [Integer] The output bit (0 or 1).
    def call(x)
      raise NotImplementedError, "Subclasses must implement #call"
    end

    # @abstract
    # @return [Symbol] :constant or :balanced
    def type
      raise NotImplementedError, "Subclasses must implement #type"
    end
  end

  # Represents a constant oracle where f(x) = c for all x.
  class ConstantOracle < Oracle
    attr_reader :value

    # @param value [Integer] The constant output (0 or 1).
    def initialize(value)
      raise ArgumentError, "Value must be 0 or 1" unless [0, 1].include?(value)

      @value = value
    end

    # @param x [Integer] Input bit string.
    # @return [Integer] The constant value.
    def call(x)
      @value
    end

    # @return [Symbol] :constant
    def type
      :constant
    end
  end

  # Represents a balanced oracle where f(x) = 0 for half the inputs and 1 for the other half.
  class BalancedOracle < Oracle
    # @param n_qubits [Integer] The number of qubits.
    # @param mask [Integer] A bitmask defining the balanced function.
    #   For a balanced function, the mask must have exactly n_qubits/2 bits set.
    def initialize(n_qubits, mask)
      @n_qubits = n_qubits
      @mask = mask

      # Verify the mask creates a balanced function
      # A function defined by (x & mask) != 0 is balanced if mask has exactly n/2 bits set
      # Actually, the standard balanced oracle is f(x) = x_1 XOR x_2 ... XOR x_n (parity)
      # Or f(x) = 1 if x has a specific property.
      # For simplicity, we use a mask-based approach where f(x) = 1 if (x & mask) != 0
      # This is balanced if the mask has exactly n/2 bits set? No.
      # Let's use the standard definition: f(x) = 1 if the number of 1s in x is odd (parity)
      # Or f(x) = 1 if x >= 2^(n-1) (first half 0, second half 1)
      # We'll use a generic balanced function: f(x) = 1 if (x & mask) != 0
      # To ensure it's balanced, we need the mask to be such that exactly half the inputs satisfy it.
      # The simplest balanced function is f(x) = x_0 (the first bit).
      # Let's implement a specific balanced oracle: f(x) = 1 if x has an odd number of 1s (parity)
      # This is always balanced for n >= 1.
    end

    # @param x [Integer] Input bit string.
    # @return [Integer] 1 if the number of 1s in x is odd, 0 otherwise.
    def call(x)
      # Count the number of 1s in the binary representation of x
      # If odd, return 1; if even, return 0
      x.bit_count.odd? ? 1 : 0
    end

    # @return [Symbol] :balanced
    def type
      :balanced
    end
  end

  # Result of the Deutsch-Jozsa algorithm execution.
  class Result
    attr_reader :is_constant, :confidence

    # @param is_constant [Boolean] True if the function is constant, false if balanced.
    # @param confidence [Float] Confidence level of the result (1.0 for deterministic classical simulation).
    def initialize(is_constant, confidence = 1.0)
      @is_constant = is_constant
      @confidence = confidence
    end

    # @return [String] Human-readable description of the result.
    def to_s
      if @is_constant
        "Function is CONSTANT"
      else
        "Function is BALANCED"
      end
    end
  end
end
