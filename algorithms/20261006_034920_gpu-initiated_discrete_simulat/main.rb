require 'minitest/autorun'
require 'benchmark'
require_relative 'core'

# Simple logistic map update function for vector state.
LOGISTIC_UPDATE = lambda do |state|
  r = 3.9
  state.map { |x| r * x * (1 - x) }
end

class TestSimulator < Minitest::Test
  def setup
    @initial_state = Array.new(5) { rand }
    @sim = Bifurcation::Simulator.new(@initial_state, LOGISTIC_UPDATE, 1e-4)
  end

  def test_initialization
    assert_equal @initial_state, @sim.state
    refute @sim.bifurcated?
  end

  def test_step
    old_state = @sim.state
    new_state = @sim.step
    refute_equal old_state, new_state
    assert_equal @initial_state.size, new_state.size
  end

  def test_bifurcation_detection
    200.times { @sim.step }
    assert @sim.bifurcated?, 'Bifurcation should be detected after many steps'
  end

  def test_stream_dense
    rows = []
    @sim.stream_dense(4, 2) { |row| rows << row }
    assert_equal 4, rows.size
    rows.each { |row| assert_equal 4, row.size }
  end
end

# Benchmarking
if __FILE__ == $0
  sim = Bifurcation::Simulator.new(Array.new(10) { 0.5 }, LOGISTIC_UPDATE, 1e-4)
  Benchmark.bmbm do |x|
    x.report('step 1000') { 1000.times { sim.step } }
    x.report('stream_dense 100x100') do
      sim.stream_dense(100, 20) { |row| }
    end
  end
end
