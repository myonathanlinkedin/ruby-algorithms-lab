require 'securerandom'

module SafeOptimisticLock
  # Represents a versioned record in the system.
  # In a real database, this would be a row with a version column.
  class Record
    attr_reader :id, :data, :version

    def initialize(id, data, version = 0)
      @id = id
      @data = data
      @version = version
    end

    def to_s
      "Record(id: #{@id}, data: #{@data.inspect}, version: #{@version})"
    end

    def ==(other)
      other.is_a?(Record) &&
        @id == other.id &&
        @data == other.data &&
        @version == other.version
    end
  end

  # Represents a transaction that may perform multiple read/write operations.
  class Transaction
    attr_reader :id, :operations

    def initialize(id, operations = [])
      @id = id
      @operations = operations
    end

    def to_s
      "Transaction(id: #{@id}, ops: #{@operations.length})"
    end
  end

  # Represents the result of a transaction attempt.
  class TransactionResult
    attr_reader :success, :error, :final_version

    def initialize(success, error = nil, final_version = nil)
      @success = success
      @error = error
      @final_version = final_version
    end

    def to_s
      if @success
        "Success (version: #{@final_version})"
      else
        "Failure (#{@error})"
      end
    end
  end

  # Custom exception for optimistic lock conflicts.
  class ConflictError < StandardError
    attr_reader :expected_version, :actual_version

    def initialize(expected_version, actual_version)
      @expected_version = expected_version
      @actual_version = actual_version
      super("Optimistic lock conflict: expected version #{expected_version}, found #{actual_version}")
    end
  end

  # Custom exception for invalid operations.
  class ValidationError < StandardError
  end
end
