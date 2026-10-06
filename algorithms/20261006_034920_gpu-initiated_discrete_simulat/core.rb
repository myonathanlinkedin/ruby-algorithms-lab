module Bifurcation
  # Simulator for discrete dynamical systems with bifurcation detection.
  class Simulator
    # Public: Create a new simulator.
    #
    # Parameters:
    #   initial_state   - Array<Float> initial state vector.
    #   update_function - Proc that takes an Array<Float> and returns a new Array<Float>.
    #   threshold       - Float, difference threshold to flag bifurcation.
    def initialize(initial_state, update_function, threshold = 1e-6)
      @state = initial_state.dup
      @update_function = update_function
      @threshold = threshold
      @history = [@state.dup]
      @bifurcated = false
      @mutex = Mutex.new
    end

    # Public: Advance the simulation by one step.
    #
    # Returns: Array<Float> new state.
    def step
      @mutex.synchronize do
        new_state = @update_function.call(@state)
        diff = max_abs_diff(@state, new_state)
        @bifurcated ||= diff > @threshold
        @state = new_state
        @history << @state.dup
        @state
      end
    end

    # Public: Run the simulation for n steps.
    #
    # Parameters:
    #   n - Integer number of steps.
    #
    # Returns: Array<Array<Float>> history of states.
    def run(n)
      n.times { step }
      @history.dup
    end

    # Public: Current state vector.
    #
    # Returns: Array<Float>.
    def state
      @mutex.synchronize { @state.dup }
    end

    # Public: Whether a bifurcation has been detected.
    #
    # Returns: Boolean.
    def bifurcated?
      @mutex.synchronize { @bifurcated }
    end

    # Public: Stream a dense matrix derived from the current state.
    #
    # Parameters:
    #   size - Integer size of the square matrix.
    #   block_size - Integer number of rows per block yielded.
    #
    # Yields: Array<Float> each row of the matrix.
    def stream_dense(size, block_size = 10)
      raise ArgumentError, 'size must be positive' if size <= 0
      raise ArgumentError, 'block_size must be positive' if block_size <= 0
      @mutex.synchronize do
        matrix = Array.new(size) do |i|
          Array.new(size) { |j| @state[i % @state.size] * @state[j % @state.size] }
        end
        matrix.each_slice(block_size) do |block|
          block.each { |row| yield row }
        end
      end
    end

    private

    # Compute maximum absolute difference between two vectors.
    def max_abs_diff(a, b)
      a.zip(b).map { |x, y| (x - y).abs }.max
    end
  end
end
