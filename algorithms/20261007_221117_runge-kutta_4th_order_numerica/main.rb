require_relative 'core'
require 'minitest/autorun'

class TestRK4 < Minitest::Test
  TOL = 1e-5

  def test_exponential_growth
    f = ->(_t, y) { y }               # dy/dt = y
    rk = ODE::RK4.new(0.1)
    points = rk.integrate(f, 0.0, 1.0, 1.0)
    last = points[-1][1]
    expected = Math.exp(1.0)
    assert_in_delta expected, last, TOL
  end

  def test_exponential_decay
    f = ->(_t, y) { -y }              # dy/dt = -y
    rk = ODE::RK4.new(0.05)
    points = rk.integrate(f, 0.0, 2.0, 1.0)
    last = points[-1][1]
    expected = Math.exp(-2.0)
    assert_in_delta expected, last, TOL
  end

  def test_harmonic_oscillator
    f = ->(_t, s) { [s[1], -s[0]] }   # x' = v, v' = -x
    rk = ODE::RK4.new(0.01)
    points = rk.integrate(f, 0.0, Math::PI, [0.0, 1.0]) # sin(t) solution
    last_state = points[-1][1]
    assert_in_delta Math.sin(Math::PI), last_state[0], TOL
    assert_in_delta Math.cos(Math::PI), last_state[1], TOL
  end
end

# Demonstration when executed directly
if __FILE__ == $0
  puts "Demo: dy/dt = -2*y, y(0)=1, integrate to t=5"
  f = ->(_t, y) { -2.0 * y }
  rk = ODE::RK4.new(0.2)
  result = rk.integrate(f, 0.0, 5.0, 1.0)
  result.each do |t, y|
    puts format('t=%.2f y=%.5f', t, y)
  end
end
