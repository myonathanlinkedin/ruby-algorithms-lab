class CycleError < StandardError; end

Node = Struct.new(:id)

Edge = Struct.new(:from, :to)
end
