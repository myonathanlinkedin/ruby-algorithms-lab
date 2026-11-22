# Verification driver, unit tests, and demonstration

require_relative 'engine'
require 'test/unit'

class TestSVDLowRank < Test::Unit::TestCase
  include MatrixOps
  include SVDEngine

  def assert_matrix_equal(expected, actual, delta = 1e-6)
    assert_equal(expected.length, actual.length, 'Row count mismatch')
    expected.each_index do |i|
      assert_equal(expected[i].length, actual[i].length, "Column count mismatch at row #{i}")
      expected[i].each_index do |j|
        assert_in_delta(expected[i][j], actual[i][j], delta, "Mismatch at (#{i},#{j})")
      end
    end
  end

  def test_full_svd_on_symmetric_2x2
    a = [[3.0, 1.0],
         [1.0, 3.0]]
    approx, result = SVDEngine.low_rank_approximation(a, 2)

    # Expected singular values are 4 and 2 (order descending)
    expected_s = [4.0, 2.0]
    result.s.each_with_index do |sigma, idx|
      assert_in_delta(expected_s[idx], sigma, 1e-6, "Singular value #{idx} mismatch")
    end

    # Reconstructed matrix should be close to original
    assert_matrix_equal(a, approx, 1e-5)
  end

  def test_rank_one_approximation_error
    a = [[3.0, 1.0],
         [1.0, 3.0]]
    approx, _ = SVDEngine.low_rank_approximation(a, 1)

    # Compute Frobenius norm of the error matrix
    error = MatrixOps.subtract(a, approx)
    frob_error = Math.sqrt(error.reduce(0.0) { |s, row| s + row.reduce(0.0) { |ss, x| ss + x * x } })
    # For this matrix the optimal rank‑1 error is sqrt( (4-2)^2 ) = 2
    assert_in_delta(2.0, frob_error, 1e-5)
  end

  def test_rectangular_matrix_rank_two
    a = [[2.0, 0.0],
         [0.0, 1.0],
         [1.0, 1.0]]
    approx, result = SVDEngine.low_rank_approximation(a, 2)

    # Singular values can be verified against NumPy or analytical solution;
    # we only assert that reconstruction error is near zero.
    error = MatrixOps.subtract(a, approx)
    frob_error = Math.sqrt(error.reduce(0.0) { |s, row| s + row.reduce(0.0) { |ss, x| ss + x * x } })
    assert_in_delta(0.0, frob_error, 1e-5)
    assert_equal(2, result.s.length)
  end

  def test_zero_matrix
    a = [[0.0, 0.0],
         [0.0, 0.0]]
    approx, result = SVDEngine.low_rank_approximation(a, 1)
    assert_matrix_equal(a, approx, 1e-9)
    assert_equal(0.0, result.s[0])
  end
end

# Demonstration when the file is executed directly
if __FILE__ == $PROGRAM_NAME
  sample = [[5.0, 2.0, 1.0],
            [2.0, 3.0, 0.0],
            [1.0, 0.0, 4.0]]
  rank = 2
  approx, svd = SVDEngine.low_rank_approximation(sample, rank)

  puts 'Original matrix:'
  sample.each { |row| puts row.map { |x| sprintf('%.4f', x) }.join(' ') }

  puts "\nRank‑#{rank} approximation:"
  approx.each { |row| puts row.map { |x| sprintf('%.4f', x) }.join(' ') }

  puts "\nSingular values:"
  puts svd.s.map { |s| sprintf('%.6f', s) }.join(' ')
end
