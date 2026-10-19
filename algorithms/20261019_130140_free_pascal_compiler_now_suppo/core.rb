# frozen_string_literal: true

# Core implementation of a lightweight dynamic package system.
# Packages are registered with a name, version, dependencies and a factory block.
# The registry resolves dependencies, detects cycles, and loads packages on demand.

class Package
  attr_reader :name, :version, :dependencies, :factory

  # Initialize a new package.
  # @param name [String] unique identifier
  # @param version [String] semantic version (ignored for resolution)
  # @param dependencies [Array<String>] names of required packages
  # @param factory [Proc] block returning the module/object representing the package
  def initialize(name:, version:, dependencies: [], &factory)
    raise ArgumentError, 'name must be a non‑empty String' unless name.is_a?(String) && !name.empty?
    raise ArgumentError, 'version must be a String' unless version.is_a?(String)
    raise ArgumentError, 'dependencies must be an Array of Strings' unless dependencies.is_a?(Array) && dependencies.all? { |d| d.is_a?(String) }
    raise ArgumentError, 'factory block required' unless block_given?

    @name = name.freeze
    @version = version.freeze
    @dependencies = dependencies.map(&:freeze).freeze
    @factory = factory
  end
end

class PackageRegistry
  # Create a new empty registry.
  def initialize
    @packages = {}            # name => Package
    @loaded = {}              # name => loaded module/object
  end

  # Register a package. Overwrites an existing entry with the same name.
  # @param pkg [Package]
  def register(pkg)
    raise ArgumentError, 'pkg must be a Package' unless pkg.is_a?(Package)

    @packages[pkg.name] = pkg
    @loaded.delete(pkg.name) # ensure stale loads are cleared
    self
  end

  # Load a package by name, resolving dependencies recursively.
  # Returns the module/object produced by the package's factory.
  # @param name [String]
  # @return [Object]
  def load(name)
    raise ArgumentError, 'name must be a String' unless name.is_a?(String)

    resolve(name, [])
    @loaded[name]
  end

  # Check whether a package is already loaded.
  # @param name [String] package name
  # @return [Boolean]
  def loaded?(name)
    @loaded.key?(name)
  end

  private

  # Internal recursive resolver with cycle detection.
  # @param name [String] current package name
  # @param stack [Array<String>] call stack for cycle detection
  def resolve(name, stack)
    raise LoadError, "Package '#{name}' not registered" unless @packages.key?(name)

    return if @loaded.key?(name) # already loaded

    if stack.include?(name)
      cycle = (stack + [name]).join(' -> ')
      raise LoadError, "Circular dependency detected: #{cycle}"
    end

    pkg = @packages[name]
    # Resolve dependencies first
    pkg.dependencies.each do |dep_name|
      resolve(dep_name, stack + [name])
    end

    # After dependencies are loaded, instantiate this package
    @loaded[name] = pkg.factory.call
    @loaded[name]
  end
end
