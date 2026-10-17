class RungeKutta4
  # f is a Proc/lambda taking (t, y) and returning dy/dt (scalar or Array)
  def initialize(f)
    raise ArgumentError, "f must respond to :call" unless f.respond_to?(:call)
    @f = f
  end

  # Perform a single RK4 step.
  # t  - current time (Float)
  # y  - current state (Float or Array of Floats)
  # h  - step size (Float, >0)
  # Returns new state (same type as y)
  def step(t, y, h)
    raise ArgumentError, "step size must be positive" unless h > 0
    y_vec = to_vector(y)
    k1 = scale(@f.call(t, y_vec), h)
    k2 = scale(@f.call(t + h * 0.5, add(y_vec, scale(k1, 0.5))), h)
    k3 = scale(@f.call(t + h * 0.5, add(y_vec, scale(k2, 0.5))), h)
    k4 = scale(@f.call(t + h, add(y_vec, k3)), h)
    result = add(y_vec, scale(add(add(k1, scale(k2, 2.0)), scale(k3, 2.0)), 1.0/6.0).tap { |s| s = add(s, scale(k4, 1.0/6.0)) })
    from_vector(result, y)
  end

  # Integrate from t0 to t_end with fixed step h.
  # Returns an Array of [t, y] where y matches the input type.
  def integrate(t0, y0, t_end, h)
    raise ArgumentError, "h must be positive" unless h > 0
    raise ArgumentError, "t_end must be >= t0" unless t_end >= t0
    points = []
    t = t0
    y = y0
    points << [t, deep_copy(y)]
    while t < t_end
      step_h = [h, t_end - t].min
      y = step(t, y, step_h)
      t += step_h
      points << [t, deep_copy(y)]
    end
    points
  end

  private

  # Convert scalar or Array to Array of Floats
  def to_vector(val)
    if val.is_a?(Array)
      val.map { |e| Float(e) }
    else
      [Float(val)]
    end
  end

  # Convert back to original type (scalar or Array)
  def from_vector(vec, prototype)
    prototype.is_a?(Array) ? vec.dup : vec.first
  end

  # Element‑wise addition of two vectors
  def add(a, b)
    a.zip(b).map { |x, y| x + y }
  end

  # Scale a vector by a scalar
  def scale(vec, scalar)
    vec.map { |x| x * scalar }
  end

  # Deep copy preserving scalar/Array nature
  def deep_copy(val)
    if val.is_a?(Array)
      val.map { |e| e }
    else
      val
    end
  end
end
