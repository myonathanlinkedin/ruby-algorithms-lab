# Domain models and utility structures for SVD implementation

# Simple immutable struct to hold the result of a low‑rank SVD
SVDResult = Struct.new(:u, :s, :v) # u: m×k matrix, s: k‑element array, v: n×k matrix

module MatrixOps
  # Transpose of a matrix (Array of Array)
  def self.transpose(a)
    rows = a.length
    cols = a[0].length
    Array.new(cols) { |i| Array.new(rows) { |j| a[j][i] } }
  end

  # Matrix multiplication a (m×p) * b (p×n) → (m×n)
  def self.multiply(a, b)
    a_rows = a.length
    a_cols = a[0].length
    b_rows = b.length
    b_cols = b[0].length
    raise 'Incompatible dimensions for multiplication' unless a_cols == b_rows

    Array.new(a_rows) do |i|
      Array.new(b_cols) do |j|
        sum = 0.0
        a_cols.times { |k| sum += a[i][k] * b[k][j] }
        sum
      end
    end
  end

  # Dot product of two vectors
  def self.dot(v1, v2)
    raise 'Vectors must have same length for dot product' unless v1.length == v2.length
    v1.zip(v2).reduce(0.0) { |s, (x, y)| s + x * y }
  end

  # Euclidean norm of a vector
  def self.norm(v)
    Math.sqrt(v.reduce(0.0) { |s, x| s + x * x })
  end

  # Return a normalized copy of a vector (zero vector stays zero)
  def self.normalize(v)
    n = norm(v)
    return Array.new(v.length, 0.0) if n.zero?
    v.map { |x| x / n }
  end

  # Outer product of column vectors u (m) and v (n) → m×n matrix
  def self.outer(u, v)
    u.map { |ui| v.map { |vj| ui * vj } }
  end

  # Scalar multiplication of a matrix
  def self.scalar_multiply(mat, scalar)
    mat.map { |row| row.map { |x| x * scalar } }
  end

  # Matrix subtraction a - b (both same dimensions)
  def self.subtract(a, b)
    a.each_index.map { |i| a[i].each_index.map { |j| a[i][j] - b[i][j] } }
  end

  # Deep copy of a matrix (Array of Array)
  def self.deep_copy(a)
    a.map { |row| row.map { |x| x } }
  end
end
