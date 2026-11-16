module MemorySurvey
  # Represents memory usage statistics for a single C project.
  class ProjectMemoryInfo
    attr_reader :name, :total_memory, :heap_usage, :stack_usage,
                :dynamic_allocations, :static_allocations

    def initialize(name:, total_memory:, heap_usage:, stack_usage:,
                   dynamic_allocations:, static_allocations:)
      @name = validate_name(name)
      @total_memory = validate_non_negative_integer(total_memory, 'total_memory')
      @heap_usage = validate_non_negative_integer(heap_usage, 'heap_usage')
      @stack_usage = validate_non_negative_integer(stack_usage, 'stack_usage')
      @dynamic_allocations = validate_non_negative_integer(dynamic_allocations,
                                                          'dynamic_allocations')
      @static_allocations = validate_non_negative_integer(static_allocations,
                                                          'static_allocations')
      validate_consistency!
      freeze
    end

    private

    def validate_name(name)
      raise ArgumentError, 'name must be a non‑empty String' unless name.is_a?(String) && !name.empty?
      name
    end

    def validate_non_negative_integer(value, field)
      unless value.is_a?(Integer) && value >= 0
        raise ArgumentError, "#{field} must be a non‑negative Integer"
      end
      value
    end

    # Ensure that the sum of heap, stack and static allocations does not exceed total_memory.
    def validate_consistency!
      sum = @heap_usage + @stack_usage + @static_allocations
      if sum > @total_memory
        raise ArgumentError, 'Sum of heap, stack and static allocations exceeds total_memory'
      end
    end
  end

  # Aggregates many ProjectMemoryInfo objects and provides statistical queries.
  class Survey
    attr_reader :projects

    def initialize
      @projects = []
    end

    # Adds a ProjectMemoryInfo instance to the survey.
    def add_project(project)
      raise ArgumentError, 'project must be a ProjectMemoryInfo' unless project.is_a?(ProjectMemoryInfo)
      @projects << project
      self
    end

    # Returns the average total memory across all projects, or nil if none.
    def average_total_memory
      return nil if @projects.empty?
      sum = @projects.reduce(0) { |acc, p| acc + p.total_memory }
      sum.to_f / @projects.size
    end

    # Returns the median total memory, or nil if none.
    def median_total_memory
      return nil if @projects.empty?
      sorted = @projects.map(&:total_memory).sort
      mid = sorted.size / 2
      if sorted.size.odd?
        sorted[mid].to_f
      else
        (sorted[mid - 1] + sorted[mid]).to_f / 2
      end
    end

    # Returns the standard deviation of total memory, or nil if less than two projects.
    def stddev_total_memory
      return nil if @projects.size < 2
      avg = average_total_memory
      variance = @projects.reduce(0) { |acc, p| acc + (p.total_memory - avg)**2 } / (@projects.size - 1)
      Math.sqrt(variance)
    end

    # Returns the top n projects sorted by heap usage descending.
    def top_n_by_heap(n = 5)
      raise ArgumentError, 'n must be a positive Integer' unless n.is_a?(Integer) && n > 0
      @projects.sort_by { |p| -p.heap_usage }.first(n)
    end

    # Returns a hash mapping allocation category symbols to the count of projects
    # where that category is the dominant allocation (largest among heap, stack, static).
    def dominant_allocation_distribution
      distribution = Hash.new(0)
      @projects.each do |p|
        dominant = dominant_category(p)
        distribution[dominant] += 1
      end
      distribution
    end

    # Returns a human‑readable summary string.
    def summary
      lines = []
      lines << "Projects surveyed: #{@projects.size}"
      lines << "Average total memory: #{format_float(average_total_memory)} KiB"
      lines << "Median total memory: #{format_float(median_total_memory)} KiB"
      lines << "Stddev total memory: #{format_float(stddev_total_memory)} KiB"
      lines << "Dominant allocation distribution:"
      dominant_allocation_distribution.each do |category, count|
        lines << "  #{category}: #{count}"
      end
      lines.join("\n")
    end

    private

    def dominant_category(project)
      values = {
        heap: project.heap_usage,
        stack: project.stack_usage,
        static: project.static_allocations
      }
      values.max_by { |_, v| v }[0]
    end

    def format_float(value)
      value.nil? ? 'N/A' : format('%.2f', value)
    end
  end
end
