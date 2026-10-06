module Types
  class Scheduler
    attr_reader :jobs

    def initialize
      @jobs = []
    end

    def enqueue(job)
      @jobs << job
    end

    def dequeue
      return unless @jobs.any?

      job = @jobs.shift
      @jobs -= [job]
      job
    end
  end

  class Job
    attr_reader :data

    def initialize(data)
      @data = data
    end
  end
end
