# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'

# Demonstration package definitions
REGISTRY = PackageRegistry.new

# Base package with no dependencies
REGISTRY.register(
  Package.new(name: 'base', version: '1.0') do
    mod = Module.new
    mod.define_singleton_method(:greet) { 'Hello from Base' }
    mod
  end
)

# Utility package depending on base
REGISTRY.register(
  Package.new(name: 'util', version: '2.1', dependencies: ['base']) do
    mod = Module.new
    mod.define_singleton_method(:util_greet) { "Util says: #{REGISTRY.load('base').greet}" }
    mod
  end
)

# Composite package depending on util and base
REGISTRY.register(
  Package.new(name: 'composite', version: '0.5', dependencies: %w[util base]) do
    mod = Module.new
    mod.define_singleton_method(:composite_greet) do
      "Composite combines: #{REGISTRY.load('util').util_greet} & #{REGISTRY.load('base').greet}"
    end
    mod
  end
)

# Unit test suite for the dynamic package system
class TestPackageRegistry < Minitest::Test
  def setup
    @registry = PackageRegistry.new

    @registry.register(
      Package.new(name: 'alpha', version: '1.0') do
        mod = Module.new
        mod.define_singleton_method(:value) { 42 }
        mod
      end
    )

    @registry.register(
      Package.new(name: 'beta', version: '1.2', dependencies: ['alpha']) do
        mod = Module.new
        mod.define_singleton_method(:double) { @registry.load('alpha').value * 2 }
        mod
      end
    )
  end

  def test_simple_load
    alpha = @registry.load('alpha')
    assert_equal 42, alpha.value
    assert @registry.loaded?('alpha')
  end

  def test_dependency_resolution
    beta = @registry.load('beta')
    assert_equal 84, beta.double
    assert @registry.loaded?('beta')
    assert @registry.loaded?('alpha')
  end

  def test_idempotent_load
    first = @registry.load('alpha')
    second = @registry.load('alpha')
    assert_same first, second
  end

  def test_missing_package
    error = assert_raises(LoadError) { @registry.load('nonexistent') }
    assert_match /not registered/, error.message
  end

  def test_circular_dependency_detection
    @registry.register(
      Package.new(name: 'gamma', version: '0.1', dependencies: ['delta']) { Module.new }
    )
    @registry.register(
      Package.new(name: 'delta', version: '0.1', dependencies: ['gamma']) { Module.new }
    )
    error = assert_raises(LoadError) { @registry.load('gamma') }
    assert_match /Circular dependency detected/, error.message
  end

  def test_complex_graph
    # Register a small graph: a -> b -> c, a also -> c
    @registry.register(
      Package.new(name: 'c', version: '1.0') { Module.new }
    )
    @registry.register(
      Package.new(name: 'b', version: '1.0', dependencies: ['c']) { Module.new }
    )
    @registry.register(
      Package.new(name: 'a', version: '1.0', dependencies: %w[b c]) { Module.new }
    )
    a_mod = @registry.load('a')
    assert @registry.loaded?('a')
    assert @registry.loaded?('b')
    assert @registry.loaded?('c')
    assert_instance_of Module, a_mod
  end
end

# Demonstration execution block (runs when file is executed directly)
if __FILE__ == $0
  puts '--- Demonstration of dynamic packages ---'
  puts REGISTRY.load('base').greet
  puts REGISTRY.load('util').util_greet
  puts REGISTRY.load('composite').composite_greet
end
