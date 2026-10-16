require_relative 'types'

# Core engine implementing gradient‑descent based SMACOF‑like MDS.
class MDSRecover
  EPS = 1e-12

  def initialize(observations, n_points, config = Config.new)
    @obs = observations.map { |o| o.is_a?(Observation) ? o : Observation.new(*o) }
    @n = n_points
    @cfg = config
    validate!
    random_initialize!
  end

  # Public entry point – returns an Array of n points, each an Array of dim coordinates.
  def recover
    prev_stress = Float::INFINITY
    @cfg.max_iter.times do |iter|
      grads = Array.new(@n) { Array.new(@cfg.dim, 0.0) }
      stress = 0.0

      @obs.each do |o|
        i, j, d_target = o.i, o.j, o.distance
        diff = vector_sub(@coords[i], @coords[j])
        cur_dist = Math.sqrt(vector_norm_sq(diff)) + EPS
        delta = cur_dist - d_target
        stress += delta * delta

        # Gradient contribution
        factor = (2.0 * delta) / cur_dist
        grad = vector_scale(diff, factor)
        grads[i] = vector_add(grads[i], grad)
        grads[j] = vector_sub(grads[j], grad)
      end

      # Update step
      @n.times do |idx|
        @coords[idx] = vector_sub(@coords[idx], vector_scale(grads[idx], @cfg.learning_rate))
      end

      # Convergence check
      if @cfg.verbose && (iter % 100).zero?
        puts "Iter #{iter}: stress = #{stress}"
      end
      break if (prev_stress - stress).abs < @cfg.tolerance
      prev_stress = stress
    end
    @coords
  end

  private

  def validate!
    raise ArgumentError, "Number of points must be positive" unless @n.positive?
    raise ArgumentError, "Dimension must be positive" unless @cfg.dim.positive?
    @obs.each { |o| o.validate!(@n) }
  end

  def random_initialize!
    # Small random values centred at zero
    @coords = Array.new(@n) do
      Array.new(@cfg.dim) { rand(-0.5..0.5) }
    end
  end

  # Vector utilities (plain Ruby arrays)
  def vector_sub(a, b)
    a.zip(b).map { |x, y| x - y }
  end

  def vector_add(a, b)
    a.zip(b).map { |x, y| x + y }
  end

  def vector_scale(v, s)
    v.map { |x| x * s }
  Euclidean distance squared
  def vector_norm_sq(v)
    v.reduce(0.0) { |sum, x| sum + x * x }
  end
end
end
