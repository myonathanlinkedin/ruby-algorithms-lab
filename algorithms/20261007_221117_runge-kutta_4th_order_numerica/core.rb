module ODE
  class RK4
    # Create a new RK4 integrator with fixed step size +h+.
    def initialize(step)
      @h = step
    end

    # Integrate the ODE defined by +f+ (callable f(t, y)) from +t0+ to +t_end+
    # starting with initial state +y0+ (numeric or Array of numerics).
    # Returns an Array of [t, y] points, where y matches the type of +y0+.
    def integrate(f, t0, t_end, y0)
      h = @h
      n_steps = ((t_end - t0) / h).ceil
      t = t0
      y = deep_copy(y0)
      result = [[t, deep_copy(y)]]

      n_steps.times do
        break if t >= t_end
        h_eff = [h, t_end - t].min

        k1 = f.call(t, y)
        k2 = f.call(t + h_eff / 2.0, add(y, scale(k1, h_eff / 2.0)))
        k3 = f.call(t + h_eff / 2.0, add(y, scale(k2, h_eff / 2.0)))
        k4 = f.call(t + h_eff, add(y, scale(k3, h_eff)))

        incr = scale(
          add(
            add(k1, scale(k2, 2.0)),
            add(scale(k3, 2.0), k4)
          ),
          h_eff / 6.0
        )
        y = add(y, incr)
        t += h_eff
        result << [t, deep_copy(y)]
      end

      result
    end

    private

    def deep_copy(obj)
      obj.is_a?(Array) ? obj.map { |e| deep_copy(e) } : obj
    end

    def add(a, b)
      a.is_a?(Array) ? a.each_index.map { |i| a[i] + b[i] } : a + b
    end

    def scale(a, factor)
      a.is_a?(Array) ? a.map { |e| e * factor } : a * factor
    end
  end
end
