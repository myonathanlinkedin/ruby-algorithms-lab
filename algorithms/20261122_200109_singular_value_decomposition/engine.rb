# Core algorithmic implementation of low‑rank SVD using power iteration

require_relative 'types'

module SVDEngine
  include MatrixOps

  # Compute the top singular triplet (u, sigma, v) of matrix a using power iteration.
  # Returns [u_vector, sigma, v_vector] where u and v are normalized column vectors.
  def self.top_singular_triplet(a, max_iter = 1000, eps = 1e-10)
    m = a.length
    n = a[0].length

    # Initialise v with ones and normalize
    v = Array.new(n, 1.0)
    v = MatrixOps.normalize(v)

    sigma = 0.0
    max_iter.times do
      # u = A * v
      u = MatrixOps.multiply(a, [v]).map { |row| row[0] }
      u = MatrixOps.normalize(u)

      # v_new = Aᵀ * u
      v_new = MatrixOps.multiply(MatrixOps.transpose(a), [u]).map { |row| row[0] }
      v_new = MatrixOps.normalize(v_new)

      # Estimate singular value
      sigma_new = MatrixOps.dot(u, MatrixOps.multiply(a, [v_new]).map { |row| row[0] })

      break if (sigma - sigma_new).abs < eps

      v = v_new
      sigma = sigma_new
    end

    # Final refinement
    u = MatrixOps.multiply(a, [v]).map { |row| row[0] }
    u = MatrixOps.normalize(u)
    sigma = MatrixOps.dot(u, MatrixOps.multiply(a, [v]).map { |row| row[0] })

    [u, sigma, v]
  end

  # Compute a rank‑k approximation of matrix a.
  # Returns [approx_matrix, SVDResult]
  def self.low_rank_approximation(a, k)
    raise 'Requested rank must be positive' unless k.is_a?(Integer) && k > 0

    m = a.length
    n = a[0].length

    # Containers for singular vectors and values
    u_mat = Array.new(m) { Array.new(k, 0.0) }
    v_mat = Array.new(n) { Array.new(k, 0.0) }
    s_vals = Array.new(k, 0.0)

    # Working copy that will be deflated after each component extraction
    residual = MatrixOps.deep_copy(a)

    k.times do |idx|
      u_vec, sigma, v_vec = top_singular_triplet(residual)

      # If sigma collapses to zero, remaining components are zero
      break if sigma.zero?

      # Store the components
      m.times { |i| u_mat[i][idx] = u_vec[i] }
      n.times { |j| v_mat[j][idx] = v_vec[j] }
      s_vals[idx] = sigma

      # Deflate: residual = residual - sigma * u * vᵀ
      outer = MatrixOps.outer(u_vec, v_vec)
      subtraction = MatrixOps.scalar_multiply(outer, sigma)
      residual = MatrixOps.subtract(residual, subtraction)
    end

    # Reconstruct the low‑rank approximation from the collected components
    approx = Array.new(m) { Array.new(n, 0.0) }
    k.times do |idx|
      sigma = s_vals[idx]
      next if sigma.zero?
      outer = MatrixOps.outer(u_mat.map { |row| row[idx] }, v_mat.map { |row| row[idx] })
      approx = MatrixOps.add(approx, MatrixOps.scalar_multiply(outer, sigma))
    end

    result = SVDResult.new(u_mat, s_vals, v_mat)
    [approx, result]
  end

  # Helper to add two matrices (same dimensions)
  def self.add(a, b)
    a.each_index.map { |i| a[i].each_index.map { |j| a[i][j] + b[i][j] } }
  end
end
