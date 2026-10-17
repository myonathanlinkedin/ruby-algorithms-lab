require_relative 'core'
require 'minitest/autorun'

class TestRungeKutta4 < Minitest::Test
  TOL = 1e-6

  def test_exponential_growth
    f = ->(t, y) { y } # dy/dt = y
    rk = RungeKutta4.new(f)
    y0 = 1.0
    t0 = 0.0
    t_end = 1.0
    h = 0.1
    result = rk.integrate(t0, y0, t_end, h)
    final_y = result.last[1]
    expected = Math.exp(t_end) * y0
    assert_in_delta expected, final_y, TOL
  end

  def test_scalar_step_consistency
    f = ->(t, y) { y } # dy/dt = y
    rk = RungeKutta4.new(f)
    y = 2.0
    t = 0.0
    h = 0.2
    y1 = rk.step(t, y, h)
    # Compare with analytical solution over same interval
    expected = y * Math.exp(h)
    assert_in_delta expected, y1, TOL
  end

  def test_harmonic_oscillator
    # System: dy1/dt = y2, dy2/dt = -y1  (simple harmonic oscillator)
    f = ->(_t, y) { [y[1], -y[0]] }
    rk = RungeKutta4.new(f)
    y0 = [0.0, 1.0] # start at (x=0, v=1) => sin wave
    t0 = 0.0
    t_end = 2 * Math::PI
    h = 0.05
    points = rk.integrate(t0, y0, t_end, h)
    final_state = points.last[1]
    # Expected: x = sin(t_end) = 0, v = cos(t_end) = 1
    assert_in_delta 0.0, final_state[0], 1e-4
    assert_in_delta 1.0, final_state[1], 1e-4
    # Energy should be conserved: E = 0.5*(v^2 + x^2)
    energies = points.map { |_, y| 0.5 * (y[0]**2 + y[1]**2) }
    max_energy = energies.max
    min_energy = energies.min
    assert_in_delta max_energy, min_energy, 1e-3
  end

  def test_invalid_step_size
    f = ->(t, y) { y }
    rk = RungeKutta4.new(f)
    assert_raises(ArgumentError) { rk.step(0.0, 1.0, 0.0) }
    assert_raises(ArgumentError) { rk.integrate(0.0, 1.0, 1.0, -0.1) }
  end
end

# Demonstration when executed directly
if __FILE__ == $0
  puts "Runge‑Kutta 4th Order Integrator Demo"
  f = ->(t, y) { -2.0 * y + Math.sin(t) } # Example linear ODE
  rk = RungeKutta4.new(f)
  t0 = 0.0
  y0 = 0.0
  t_end = 10.0
  h = 0.1
  trajectory = rk.integrate(t0, y0, t_end, h)
  trajectory.each do |t, y|
    puts format('t = %.2f, y = %.6f', t, y)
  end
end
