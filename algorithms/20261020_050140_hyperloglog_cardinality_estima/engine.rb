require 'digest'
require_relative 'types'

class HyperLogLog
  attr_reader :precision, :registers, :m

  # Initialize with a Types::Config or raw precision integer
  def initialize(config_or_precision = 14)
    config = config_or_precision.is_a?(Types::Config) ? config_or_precision : Types::Config.new(config_or_precision)
    @precision = config.precision
    @m = 1 << @precision
    @registers = Array.new(@m, 0)
  end

  # Add an element (any object that responds to #to_s)
  def add(item)
    hash = hash64(item)
    idx = (hash >> (64 - @precision)) & (@m - 1)               # first p bits as bucket index
    w = (hash << @precision) & ((1 << 64) - 1)                  # remaining bits
    rank = leading_zeros(w, 64 - @precision) + 1               # position of first 1-bit
    @registers[idx] = rank if rank > @registers[idx]
    self
  end

  # Return the cardinality estimate as a Float
  def count
    alpha = case @m
            when 16 then 0.673
            when 32 then 0.697
            when 64 then 0.709
            else 0.7213 / (1.0 + 1.079 / @m)
            end

    z = @registers.map { |r| 2.0 ** -r }.sum
    raw_est = alpha * @m * @m / z

    # Small range correction (Linear Counting)
    if raw_est <= (5.0 / 2.0) * @m
      v = @registers.count(0)
      return @m * Math.log(@m.to_f / v) if v != 0
    end

    # Large range correction
    if raw_est > (1.0 / 30.0) * (2**64)
      return - (2**64) * Math.log(1.0 - raw_est / (2**64))
    end

    raw_est
  end

  # Merge another HyperLogLog into this one (in‑place)
  def merge!(other)
    raise ArgumentError, "Precision mismatch" unless other.precision == @precision
    @registers.each_index do |i|
      @registers[i] = [@registers[i], other.registers[i]].max
    end
    self
  end

  private

  # 64‑bit hash using SHA‑256, taking the most‑significant 8 bytes
  def hash64(item)
    Digest::SHA256.digest(item.to_s).unpack1('Q>') # big‑endian unsigned 64‑bit
  end

  # Count leading zeros in a value that is exactly +bits+ wide
  def leading_zeros(value, bits)
    count = 0
    (bits - 1).downto(0) do |i|
      if (value & (1 << i)).zero?
        count += 1
      else
        break
      end
    end
    count
  end
end
