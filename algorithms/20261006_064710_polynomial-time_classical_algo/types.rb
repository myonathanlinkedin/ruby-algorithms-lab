class SpinConfiguration
  attr_reader :spins

  def initialize(spins)
    @spins = spins.map { |s| s == 1 ? 1 : -1 }
  end

  def size
    @spins.size
  end
end

class InteractionMatrix
  attr_reader :matrix

  def initialize(matrix)
    @matrix = matrix.map { |row| row.map(&:to_f) }
    validate!
  end

  def size
    @matrix.size
  end

  def [](i, j)
    @matrix[i][j]
  end

  private

  def validate!
    n = @matrix.size
    @matrix.each do |row|
      raise ArgumentError, "Interaction matrix must be square" unless row.size == n
    end
    n.times do |i|
      n.times do |j|
        unless (@matrix[i][j] - @matrix[j][i]).abs < 1e-12
          raise ArgumentError, "Interaction matrix must be symmetric"
        end
      end
    end
  end
end

class MeanFieldModel
  attr_reader :interaction, :field, :temperature

  def initialize(interaction:, field:, temperature:)
    @interaction = interaction
    @field = field.map(&:to_f)
    @temperature = temperature.to_f
    validate!
  end

  def size
    @interaction.size
  end

  private

  def validate!
    n = @interaction.size
    raise ArgumentError, "Field vector size must match interaction matrix" unless @field.size == n
    raise ArgumentError, "Temperature must be positive" unless @temperature > 0.0
  end
end
