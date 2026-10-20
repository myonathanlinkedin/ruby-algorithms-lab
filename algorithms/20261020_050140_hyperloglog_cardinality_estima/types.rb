module Types
  # Simple immutable configuration for HyperLogLog
  Config = Struct.new(:precision) do
    def initialize(precision = 14)
      raise ArgumentError, "Precision must be between 4 and 16" unless (4..16).include?(precision)
      super(precision)
    end
  end
end
