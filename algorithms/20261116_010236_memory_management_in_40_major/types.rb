module Types
  # Allowed memory management strategies for C projects.
  MEMORY_STRATEGIES = [
    :manual,            # Direct use of malloc/free
    :custom_allocator, # Project-specific allocation wrappers
    :reference_counting,
    :garbage_collection,
    :smart_pointers    # Use of std::unique_ptr, std::shared_ptr, etc.
  ].freeze

  class InvalidStrategyError < StandardError; end
  class InvalidProjectError < StandardError; end

  # Immutable representation of a C project's memory‑management profile.
  class Project
    attr_reader :name, :loc, :strategies

    # name      – String identifier of the project.
    # loc       – Integer lines‑of‑code (non‑negative).
    # strategies– Array of Symbol strategies drawn from MEMORY_STRATEGIES.
    def initialize(name, loc, strategies)
      validate_name(name)
      validate_loc(loc)
      validate_strategies(strategies)

      @name = name.freeze
      @loc = loc
      @strategies = strategies.map(&:to_sym).freeze
      freeze
    end

    # Returns true if the project employs the given strategy.
    def uses_strategy?(strategy)
      @strategies.include?(strategy.to_sym)
    end

    private

    def validate_name(name)
      raise InvalidProjectError, 'name must be a non‑empty String' unless name.is_a?(String) && !name.empty?
    end

    def validate_loc(loc)
      raise InvalidProjectError, 'loc must be a non‑negative Integer' unless loc.is_a?(Integer) && loc >= 0
    end

    def validate_strategies(strategies)
      unless strategies.is_a?(Array) && !strategies.empty?
        raise InvalidProjectError, 'strategies must be a non‑empty Array'
      end

      strategies.each do |s|
        sym = s.to_sym
        unless MEMORY_STRATEGIES.include?(sym)
          raise InvalidStrategyError, "unknown strategy #{s.inspect}"
        end
      end
    end
  end
end
end
end
