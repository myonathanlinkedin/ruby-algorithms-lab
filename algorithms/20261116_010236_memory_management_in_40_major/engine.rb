require_relative 'types'

module Engine
  class Survey
    attr_reader :projects

    def initialize(projects = [])
      @projects = []
      projects.each { |p| add_project(p) }
    end

    # Adds a Types::Project instance to the survey.
    def add_project(project)
      raise Types::InvalidProjectError, 'must be a Types::Project' unless project.is_a?(Types::Project)

      @projects << project
      self
    end

    # Total number of surveyed projects.
    def total_projects
      @projects.size
    end

    # Returns a Hash mapping each strategy Symbol to the count of projects that use it.
    def count_by_strategy
      hash = Hash.new(0)
      @projects.each do |proj|
        proj.strategies.each { |s| hash[s] += 1 }
      end
      hash
    end

    # Returns the most common strategy as a two‑element Array [strategy, count].
    # If there is a tie, the first encountered in MEMORY_STRATEGIES order is returned.
    # Returns nil if no projects are present.
    def most_common_strategy
      return nil if @projects.empty?

      counts = count_by_strategy
      max_count = counts.values.max
      # Preserve deterministic order by iterating over the canonical list.
      Types::MEMORY_STRATEGIES.each do |strategy|
        return [strategy, max_count] if counts[strategy] == max_count
      end
      nil
    end

    # Returns a Hash mapping each strategy Symbol to its percentage (Float) of total projects.
    # Percentage is computed as (projects using strategy / total_projects) * 100.0.
    # Returns an empty Hash when there are no projects.
    def percentage_by_strategy
      return {} if @projects.empty?

      total = total_projects.to_f
      counts = count_by_strategy
      percentages = {}
      counts.each { |s, c| percentages[s] = (c / total) * 100.0 }
      percentages
    end

    # Returns an Array of Types::Project that employ more than one strategy.
    def projects_using_multiple_strategies
      @projects.select { |p| p.strategies.size > 1 }
    end

    # Returns an Array of Types::Project that use the specified strategy.
    def find_projects_by_strategy(strategy)
      sym = strategy.to_sym
      raise Types::InvalidStrategyError, "unknown strategy #{strategy.inspect}" unless Types::MEMORY_STRATEGIES.include?(sym)

      @projects.select { |p| p.uses_strategy?(sym) }
    end
  end
end
