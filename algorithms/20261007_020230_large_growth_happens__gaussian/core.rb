class GaussianElimination
  attr_reader :matrix, :rhs, :n

  # matrix: array of n arrays, each length n
  # rhs: array length n
  def initialize(matrix, rhs)
    @matrix = matrix.map { |row| row.map(&:to_f) }
    @rhs = rhs.map(&:to_f)
    @n = @matrix.size
    validate_dimensions!
  end

  # Solve Ax = b using Gaussian elimination with partial pivoting.
  # Returns solution array x.
  def solve
    a = deep_copy(@matrix)
    b = @rhs.dup

    # Forward elimination with partial pivoting
    (0...@n).each do |k|
      pivot_row = select_pivot(a, k)
      raise RuntimeError, "Singular matrix detected" if a[pivot_row][k].abs < 1e-12

      swap_rows(a, b, k, pivot_row) if pivot_row != k

      (k + 1...@n).each do |i|
        factor = a[i][k] / a[k][k]
        (k...@n).each do |j|
          a[i][j] -= factor * a[k][j]
        end
        b[i] -= factor * b[k]
      end
    end

    back_substitution(a, b)
  end

  # Generate a random n×n matrix with values in [-range, range]
  # and a random solution vector; returns [matrix, rhs, solution]
  def self.random_system(n, range = 10.0)
    solution = Array.new(n) { rand(-range..range) }
    matrix = Array.new(n) { Array.new(n) { rand(-range..range) } }
    rhs = matrix.map { |row| dot(row, solution) }
    [matrix, rhs, solution]
  end

  private

  def validate_dimensions!
    unless @matrix.is_a?(Array) && @matrix.all? { |r| r.is_a?(Array) && r.size == @n }
      raise ArgumentError, "Matrix must be square (n×n)."
    end
    unless @rhs.is_a?(Array) && @rhs.size == @n
      raise ArgumentError, "RHS vector size must match matrix dimensions."
    end
  end

  def deep_copy(arr)
    arr.map { |row| row.dup }
  end

  def select_pivot(a, col)
    max_row = col
    max_val = a[col][col].abs
    ((col + 1)...@n).each do |i|
      if a[i][col].abs > max_val
        max_val = a[i][col].abs
        max_row = i
      end
    end
    max_row
  end

  def swap_rows(a, b, i, j)
    a[i], a[j] = a[j], a[i]
    b[i], b[j] = b[j], b[i]
  end

  def back_substitution(a, b)
    x = Array.new(@n, 0.0)
    (@n - 1).downto(0) do |i|
      sum = b[i]
      (i + 1...@n).each { |j| sum -= a[i][j] * x[j] }
      x[i] = sum / a[i][i]
    end
    x
  end

  def self.dot(v1, v2)
    v1.zip(v2).reduce(0.0) { |s, (x, y)| s + x * y }
  end
end
