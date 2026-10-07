require 'minitest/autorun'
require_relative 'core'

class TestGaussianElimination < Minitest::Test
  def test_known_system
    a = [
      [2.0, 1.0, -1.0],
      [-3.0, -1.0, 2.0],
      [-2.0, 1.0, 2.0]
    ]
    b = [8.0, -11.0, -3.0]
    solver = GaussianElimination.new(a, b)
    x = solver.solve
    expected = [2.0, 3.0, -1.0]
    assert_all_close(x, expected)
  end

  def test_random_system
    10.times do
      n = rand(2..6)
      matrix, rhs, solution = GaussianElimination.random_system(n, 20.0)
      solver = GaussianElimination.new(matrix, rhs)
      computed = solver.solve
      assert_all_close(computed, solution, epsilon: 1e-8)
    end
  end

  def test_singular_matrix
    a = [
      [1.0, 2.0],
      [2.0, 4.0] # Row 2 is a multiple of Row 1
    ]
    b = [3.0, 6.0]
    solver = GaussianElimination.new(a, b)
    assert_raises(RuntimeError) { solver.solve }
  end

  private

  def assert_all_close(actual, expected, epsilon: 1e-6)
    assert_equal expected.size, actual.size, "Vector size mismatch"
    actual.each_with_index do |val, idx|
      diff = (val - expected[idx]).abs
      assert diff < epsilon, "At index #{idx}: #{val} vs #{expected[idx]} (diff #{diff})"
    end
  end
end

if __FILE__ == $0
  # Run the test suite when executed directly.
  Minitest.run
end
