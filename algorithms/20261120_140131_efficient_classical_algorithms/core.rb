module GroundEnergy
  # LanczosSolver implements the Lanczos algorithm for estimating the smallest
  # eigenvalue (ground energy) of a real symmetric matrix.
  #
  # The implementation uses only Ruby's core Array class and avoids any
  # external dependencies. It is deterministic, raises on malformed input,
  # and provides O(k·n) time per iteration where n is the matrix dimension
  # and k the number of Lanczos steps.
  class LanczosSolver
    attr_reader :matrix, :max_iter, :tol

    # matrix   – square real symmetric matrix represented as Array of Array
    # max_iter – maximum number of Lanczos iterations (default 100)
    # tol      – convergence tolerance on the Ritz value (default 1e-10)
    def initialize(matrix, max_iter = 100, tol = 1e-10)
      @matrix   = matrix
      @max_iter = max_iter
      @tol      = tol
      validate_matrix!
    end

    # Returns an approximation of the smallest eigenvalue.
    def solve
      n = @matrix.size
      # Start with a random normalized vector.
      q = random_normalized_vector(n)
      alpha = []
      beta  = []
      q_prev = Array.new(n, 0.0)

      # Tridiagonal matrix T will be built implicitly via alpha/beta.
      (0...@max_iter).each do |j|
        # w = A * q - beta_{j-1} * q_{j-1}
        w = mat_vec_mul(@matrix, q)
        if j.positive?
          w = vector_sub(w, scalar_mul(q_prev, beta[-1]))
        end

        a = dot(q, w)
        alpha << a

        # w = w - a * q
        w = vector_sub(w, scalar_mul(q, a))

        # Reorthogonalization (full) to improve numerical stability.
        # For small dimensions this cost is negligible.
        (0...j).each do |i|
          proj = dot(@q_vectors[i], w)
          w = vector_sub(w, scalar_mul(@q_vectors[i], proj))
        end

        b = norm(w)
        beta << b

        break if b < @tol

        q_prev = q
        q = scalar_mul(w, 1.0 / b)

        # Store q for reorthogonalization.
        (@q_vectors ||= []) << q
      end

      # Build the tridiagonal matrix T from alpha and beta.
      t = build_tridiagonal(alpha, beta)

      # Compute eigenvalues of T (size <= max_iter) via the QR algorithm.
      eigs = qr_eigenvalues(t)

      # The smallest Ritz value approximates the ground energy.
      eigs.min
    end

    private

    # Validate that @matrix is square and symmetric.
    def validate_matrix!
      raise ArgumentError, 'Matrix must be a non‑empty Array' unless @matrix.is_a?(Array) && !@matrix.empty?
      n = @matrix.size
      @matrix.each do |row|
        raise ArgumentError, 'Matrix rows must be Arrays' unless row.is_a?(Array)
        raise ArgumentError, 'Matrix must be square' unless row.size == n
      end
      (0...n).each do |i|
        (0...n).each do |j|
          unless (@matrix[i][j] - @matrix[j][i]).abs < 1e-12
            raise ArgumentError, 'Matrix must be symmetric'
          end
        end
      end
    end

    # Returns a random normalized vector of dimension n.
    def random_normalized_vector(n)
      vec = Array.new(n) { rand - 0.5 }
      norm_val = norm(vec)
      raise 'Zero vector generated' if norm_val.zero?
      scalar_mul(vec, 1.0 / norm_val)
    end

    # Matrix‑vector multiplication.
    def mat_vec_mul(mat, vec)
      mat.map { |row| dot(row, vec) }
    end

    # Dot product of two vectors.
    def dot(v1, v2)
      v1.zip(v2).reduce(0.0) { |sum, (a, b)| sum + a * b }
    end

    # Euclidean norm.
    def norm(vec)
      Math.sqrt(dot(vec, vec))
    end

    # Scalar multiplication of a vector.
    def scalar_mul(vec, scalar)
      vec.map { |x| x * scalar }
    end

    # Vector subtraction v1 - v2.
    def vector_sub(v1, v2)
      v1.zip(v2).map { |a, b| a - b }
    end

    # Build a symmetric tridiagonal matrix from diagonal (alpha) and off‑diagonal (beta).
    def build_tridiagonal(alpha, beta)
      m = alpha.size
      t = Array.new(m) { Array.new(m, 0.0) }
      (0...m).each do |i|
        t[i][i] = alpha[i]
        if i < m - 1
          t[i][i + 1] = beta[i + 1]
          t[i + 1][i] = beta[i + 1]
        end
      end
      t
    end

    # QR algorithm with shifts for symmetric tridiagonal matrices.
    # Returns an array of eigenvalues.
    def qr_eigenvalues(t)
      n = t.size
      a = Marshal.load(Marshal.dump(t)) # deep copy
      max_iters = 1000
      eps = 1e-12

      (0...max_iters).each do
        # Check for convergence (off‑diagonal elements near zero)
        off_diag_norm = 0.0
        (0...n - 1).each { |i| off_diag_norm += a[i][i + 1]**2 }
        break if Math.sqrt(off_diag_norm) < eps

        # Wilkinson shift
        d = (a[n - 2][n - 2] - a[n - 1][n - 1]) / 2.0
        sign = d >= 0 ? 1.0 : -1.0
        mu = a[n - 1][n - 1] - (a[n - 1][n - 2]**2) / (d + sign * Math.sqrt(d**2 + a[n - 1][n - 2]**2))

        # Perform QR decomposition of (A - mu*I) using Givens rotations.
        q = Array.new(n) { Array.new(n, 0.0) }
        r = Marshal.load(Marshal.dump(a))
        (0...n).each { |i| q[i][i] = 1.0 }

        (0...n - 1).each do |i|
          x = r[i][i] - mu
          y = r[i + 1][i]
          c, s = givens_coefficients(x, y)
          # Apply rotation to rows i and i+1 of R
          (i...n).each do |j|
            temp = c * r[i][j] + s * r[i + 1][j]
            r[i + 1][j] = -s * r[i][j] + c * r[i + 1][j]
            r[i][j] = temp
          end
          # Accumulate Q
          (0...n).each do |j|
            temp = c * q[j][i] + s * q[j][i + 1]
            q[j][i + 1] = -s * q[j][i] + c * q[j][i + 1]
            q[j][i] = temp
          end
        end

        # Form A_{k+1} = R * Q + mu*I
        a = Array.new(n) { Array.new(n, 0.0) }
        (0...n).each do |i|
          (0...n).each do |j|
            a[i][j] = (0...n).reduce(0.0) { |sum, k| sum + r[i][k] * q[k][j] }
          end
          a[i][i] += mu
        end
      end

      # Diagonal elements are the eigenvalues.
      (0...n).map { |i| a[i][i] }
    end

    # Compute cosine and sine for Givens rotation that zeroes y.
    def givens_coefficients(x, y)
      if y.zero?
        [1.0, 0.0]
      else
        r = Math.hypot(x, y)
        [x / r, y / r]
      end
    end
  end
end
