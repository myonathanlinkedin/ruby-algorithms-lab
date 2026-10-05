# frozen_string_literal: true

# Domain models and interfaces for the Go Toolchain Hooking Architecture.
# This module defines the core data structures used to represent toolchain
# components, hook points, and execution contexts.

module GoToolchain
  # Represents a specific component within the Go toolchain (e.g., 'go', 'build', 'test').
  class Component
    attr_reader :name, :version, :path

    def initialize(name, version: nil, path: nil)
      @name = name.to_s
      @version = version
      @path = path
    end

    def to_s
      "Component(#{@name}#{@version ? " v#{@version}" : ''})"
    end

    def ==(other)
      other.is_a?(Component) && @name == other.name && @version == other.version
    end
  end

  # Represents a hook point in the toolchain execution flow.
  class HookPoint
    # Hook phases
    PRE_EXECUTION = :pre_execution
    POST_EXECUTION = :post_execution
    ON_ERROR = :on_error

    attr_reader :phase, :component, :priority

    def initialize(phase, component, priority: 0)
      @phase = phase
      @component = component
      @priority = priority
    end

    def to_s
      "HookPoint(#{@phase}, #{@component.name}, priority: #{@priority})"
    end
  end

  # Represents the context in which a hook is executed.
  class HookContext
    attr_reader :component, :args, :env, :timestamp

    def initialize(component, args: [], env: {})
      @component = component
      @args = args
      @env = env
      @timestamp = Time.now
    end

    def to_s
      "HookContext(#{@component.name}, args: #{@args.inspect})"
    end
  end

  # Represents the result of a hook execution.
  class HookResult
    attr_reader :success, :output, :error, :duration

    def initialize(success, output: nil, error: nil, duration: 0.0)
      @success = success
      @output = output
      @error = error
      @duration = duration
    end

    def to_s
      @success ? "HookResult(success, output: #{@output.inspect})" : "HookResult(failure, error: #{@error.inspect})"
    end
  end

  # Interface for hook handlers.
  module HookHandler
    def handle(context)
      raise NotImplementedError, "#{self.class} must implement #handle"
    end
  end
end
