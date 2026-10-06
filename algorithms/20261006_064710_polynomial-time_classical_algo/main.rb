require_relative 'engine'
require 'test/unit'

class TestMeanFieldSolver < Test::Unit::TestCase
  def test_fully_connected_zero_field
    n = 4
    j = 1.0
    matrix = Array.new(n) { Array.new(n, j) }
    n.times { |i| matrix[i][i] = 0.0 }
    interaction = InteractionMatrix.new(matrix)
    field = Array.new(n, 0.0)
    temperature = 2.5

    model = MeanFieldModel.new(interaction: interaction, field: field, temperature: temperature)
    solver = MeanFieldSolver.new(tolerance: 1e-10, max_iter: 5000)
    mags = solver.solve(model)

    mags.each do |m|
      assert_in_delta 0.0, m, 1e-6, "Magnetization should be near zero"
    end
  end

  def test_low_temperature_spontaneous_magnetization
    n = 3
    j = 1.0
    matrix = Array.new(n) { Array.new(n, j) }
    n.times { |i| matrix[i][i] = 0.0 }
    interaction = InteractionMatrix.new(matrix)
    field = Array.new(n, 0.0)
    temperature = 0.5

    model = MeanFieldModel.new(interaction: interaction, field: field, temperature: temperature)
    solver = MeanFieldSolver.new(tolerance: 1e-12, max_iter: 10_000)
    mags = solver.solve(model)

    avg = mags.inject(:+) / mags.size
    assert_not_equal 0.0, avg.abs, "Average magnetization should be non-zero at low T"
    mags.each do |m|
      assert_in_delta avg, m, 1e-5, "All spins should align"
    end
  end

  def test_external_field_breaks_symmetry
    n = 2
    matrix = [[0.0, 0.8], [0.8, 0.0]]
    interaction = InteractionMatrix.new(matrix)
    field = [0.3, -0.1]
    temperature = 1.0

    model = MeanFieldModel.new(interaction: interaction, field: field, temperature: temperature)
    solver = MeanFieldSolver.new
    mags = solver.solve(model)

    assert mags[0] > mags[1], "Spin 0 should have larger magnetization due to larger field"
  end
end

if __FILE__ == $0
  n = 5
  j = 0.6
  matrix = Array.new(n) { Array.new(n, j) }
  n.times { |i| matrix[i][i] = 0.0 }
  interaction = InteractionMatrix.new(matrix)
  field = Array.new(n, 0.0)
  temperature = 1.2

  model = MeanFieldModel.new(interaction: interaction, field: field, temperature: temperature)
  solver = MeanFieldSolver.new
  mags = solver.solve(model)

  puts "Mean-field magnetizations (T=#{temperature}):"
  mags.each_with_index { |m, i| puts "  m_#{i} = #{format('%.6f', m)}" }
end
