require_relative 'types'

module ODE
  class RK4Integrator
    def initialize(step_size)
      @h = step_size
    end

    def integrate(system, t0, y0, t_end)
      results = []
      t = t0
      y = y0
      results << StepResult.new(t, y)

      while t < t_end
        h = [@h, t_end - t].min

        k1 = system.derivative(t, y)
        k2 = system.derivative(t + h / 2.0, add(y, scale(k1, h / 2.0)))
        k3 = system.derivative(t + h / 2.0, add(y, scale(k2, h / 2.0)))
        k4 = system.derivative(t + h, add(y, scale(k3, h)))

        delta = scale(add(add(k1, scale(k2, 2.0)), add(scale(k3, 2.0), k4)), h / 6.0)

        y = add(y, delta)
        t += h
        results << StepResult.new(t, y)
      end

      results
    end

    private

    def add(a, b)
      if a.is_a?(Array)
        a.zip(b).map { |x, y| x + y }
      else
        a + b
      end
    end

    def scale(v, s)
      if v.is_a?(Array)
        v.map { |x| x * s }
      else
        v * s
      end
    end
  end
end
