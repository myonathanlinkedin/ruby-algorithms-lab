require_relative 'engine'
require 'minitest/autorun'

class TestRK4Integrator < Minitest::Test
  def setup
    @tolerance = 1e-6
  end

  def test_scalar_constant_derivative
    system = ODE::ODESystem.new { |t, y| 1.0 }
    integrator = ODE::RK4Integrator.new(0.1)
    results = integrator.integrate(system, 0.0, 0.0, 1.0)
    final = results.last.y
    assert_in_delta 1.0, final, @tolerance
  end

  def test_scalar_exponential_decay
    system = ODE::ODESystem.new { |t, y| -y }
    integrator = ODE::RK4Integrator.new(0.05)
    results = integrator.integrate(system, 0.0, 1.0, 1.0)
    final = results.last.y
    assert_in_delta Math.exp(-1.0), final, @tolerance
  end
end
