require 'minitest/autorun'
require_relative 'core'

class StarCaptureTest < Minitest::Test
  # Verify the theoretical bound for several star sizes.
  def test_worst_case_bounds
    (3..6).each do |n|
      steps = StarCapture.worst_case_steps(n)
      assert steps, "Strategy should guarantee capture for n=#{n}"
      assert_operator steps, :<=, 2 * n,
        "Capture should occur within 2n steps (got #{steps} for n=#{n})"
    end
  end

  # Randomised concrete simulations to ensure the implementation behaves as
  # expected for non‑adversarial targets.
  def test_random_simulations
    rng = Random.new(42)
    (2..5).each do |n|
      20.times do
        start = rng.rand(1..n) # start on a leaf
        policy = lambda do |pos, _step|
          if pos == :center
            # move to a random leaf (could stay on the same leaf)
            rng.rand(1..n)
          else
            :center
          end
        end
        steps = StarCapture.simulate(n, start, 2 * n, policy)
        assert steps, "Simulation failed to capture for n=#{n}, start=#{start}"
        assert_operator steps, :<=, 2 * n
      end
    end
  end

  # Benchmark the worst‑case computation for a moderate star size.
  def test_benchmark_worst_case
    n = 10
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    steps = StarCapture.worst_case_steps(n)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    assert steps, "Strategy should succeed for n=#{n}"
    assert_operator steps, :<=, 2 * n
    # The exhaustive search is exponential but bounded by 2n; ensure it stays fast.
    assert_operator duration, :<, 0.5, "Computation took too long (#{duration}s)"
  end
end

# Entry point for manual execution.
if __FILE__ == $PROGRAM_NAME
  puts "Running verification for star sizes 2..8..."
  (2..8).each do |n|
    steps = StarCapture.worst_case_steps(n)
    if steps
      puts "n=#{n}: guaranteed capture within #{steps} steps (≤ #{2 * n})"
    else
      puts "n=#{n}: strategy does NOT guarantee capture."
    end
  end
end
