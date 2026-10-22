# Domain models for the Windows 11 / Windows 95 Memory Manager compatibility layer.
# This module defines the core data structures that represent the legacy memory
# management subsystems (Small Model, Medium Model, Large Model) and the modern
# Windows 11 memory manager, along with the compatibility shim that bridges them.

module WinMemory
  # Represents a memory segment in the legacy Windows 95 memory model.
  # In the 16-bit era, memory was divided into segments of 64KB.
  class LegacySegment
    attr_reader :segment_selector, :base_address, :size, :access_flags

    # @param segment_selector [Integer] 16-bit segment selector
    # @param base_address [Integer] Physical base address (32-bit)
    # @param size [Integer] Size in bytes (max 64KB for 16-bit segments)
    # @param access_flags [Integer] Bitmask of access permissions
    def initialize(segment_selector, base_address, size, access_flags)
      raise ArgumentError, "Segment selector must be 16-bit" unless (0..0xFFFF).cover?(segment_selector)
      raise ArgumentError, "Base address must be 32-bit" unless (0..0xFFFFFFFF).cover?(base_address)
      raise ArgumentError, "Size must be positive" unless size > 0
      raise ArgumentError, "Size exceeds 64KB segment limit" if size > 0x10000

      @segment_selector = segment_selector
      @base_address = base_address
      @size = size
      @access_flags = access_flags
    end

    # Check if a virtual address falls within this segment
    def contains?(virtual_address)
      offset = virtual_address - @base_address
      offset >= 0 && offset < @size
    end

    def to_s
      "LegacySegment(sel=0x#{format('%04X', @segment_selector)}, base=0x#{format('%08X', @base_address)}, size=#{@size})"
    end
  end

  # Represents a memory region in the modern Windows 11 memory manager.
  # Uses 64-bit virtual addresses and page-based allocation (4KB pages).
  class ModernMemoryRegion
    attr_reader :base_address, :size, :protection, :state

    # @param base_address [Integer] 64-bit virtual base address
    # @param size [Integer] Size in bytes
    # @param protection [Symbol] :read, :write, :execute, :read_write, :read_execute, :write_execute, :read_write_execute
    # @param state [Symbol] :committed, :reserved, :free
    def initialize(base_address, size, protection, state)
      raise ArgumentError, "Base address must be non-negative" unless base_address >= 0
      raise ArgumentError, "Size must be positive" unless size > 0
      raise ArgumentError, "Invalid protection" unless VALID_PROTECTIONS.include?(protection)
      raise ArgumentError, "Invalid state" unless VALID_STATES.include?(state)

      @base_address = base_address
      @size = size
      @protection = protection
      @state = state
    end

    # Check if a virtual address falls within this region
    def contains?(virtual_address)
      offset = virtual_address - @base_address
      offset >= 0 && offset < @size
    end

    # Align address to page boundary (4KB)
    def self.page_align(address)
      (address >> 12) << 12
    end

    # Number of pages in this region
    def page_count
      (@size + 0xFFF) >> 12
    end

    def to_s
      "ModernRegion(base=0x#{format('%016X', @base_address)}, size=#{@size}, prot=#{@protection}, state=#{@state})"
    end

    VALID_PROTECTIONS = [:read, :write, :execute, :read_write, :read_execute, :write_execute, :read_write_execute].freeze
    VALID_STATES = [:committed, :reserved, :free].freeze
  end

  # Represents the legacy Windows 95 memory model type.
  # Windows 95 supported three memory models:
  # - Small Model: 64KB code, 64KB data (16-bit pointers)
  # - Medium Model: 1MB code, 64KB data (32-bit code pointers, 16-bit data pointers)
  # - Large Model: 2GB code, 2GB data (32-bit pointers for both)
  class LegacyMemoryModel
    attr_reader :model_type, :code_segment_size, :data_segment_size, :pointer_width_code, :pointer_width_data

    # @param model_type [Symbol] :small, :medium, :large
    def initialize(model_type)
      raise ArgumentError, "Invalid model type" unless VALID_MODELS.include?(model_type)

      @model_type = model_type
      case model_type
      when :small
        @code_segment_size = 0x10000   # 64KB
        @data_segment_size = 0x10000   # 64KB
        @pointer_width_code = 16
        @pointer_width_data = 16
      when :medium
        @code_segment_size = 0x100000  # 1MB
        @data_segment_size = 0x10000   # 64KB
        @pointer_width_code = 32
        @pointer_width_data = 16
      when :large
        @code_segment_size = 0x80000000 # 2GB
        @data_segment_size = 0x80000000 # 2GB
        @pointer_width_code = 32
        @pointer_width_data = 32
      end
    end

    # Maximum number of segments for this model
    def max_segments
      case @model_type
      when :small then 0xFFFF
      when :medium then 0xFFFF
      when :large then 0xFFFF
      end
    end

    # Check if a given size fits within the segment limit
    def fits_in_segment?(size)
      size <= @code_segment_size && size <= @data_segment_size
    end

    def to_s
      "LegacyModel(#{@model_type}, code=#{@code_segment_size}, data=#{@data_segment_size})"
    end

    VALID_MODELS = [:small, :medium, :large].freeze
  end

  # Represents a compatibility shim entry that maps legacy 16-bit segment
  # references to modern 64-bit virtual addresses.
  class CompatShimEntry
    attr_reader :legacy_selector, :legacy_offset, :modern_address, :legacy_model

    # @param legacy_selector [Integer] 16-bit segment selector
    # @param legacy_offset [Integer] 16-bit offset within segment
    # @param modern_address [Integer] 64-bit virtual address
    # @param legacy_model [LegacyMemoryModel] The legacy model this entry belongs to
    def initialize(legacy_selector, legacy_offset, modern_address, legacy_model)
      raise ArgumentError, "Selector must be 16-bit" unless (0..0xFFFF).cover?(legacy_selector)
      raise ArgumentError, "Offset must be 16-bit" unless (0..0xFFFF).cover?(legacy_offset)
      raise ArgumentError, "Modern address must be non-negative" unless modern_address >= 0
      raise ArgumentError, "Invalid legacy model" unless legacy_model.is_a?(LegacyMemoryModel)

      @legacy_selector = legacy_selector
      @legacy_offset = legacy_offset
      @modern_address = modern_address
      @legacy_model = legacy_model
    end

    # Compute the legacy linear address (selector * 16 + offset)
    def legacy_linear_address
      (@legacy_selector << 4) + @legacy_offset
    end

    def to_s
      "ShimEntry(sel=0x#{format('%04X', @legacy_selector)}, off=0x#{format('%04X', @legacy_offset)} -> 0x#{format('%016X', @modern_address)})"
    end
  end

  # Represents a memory access request that needs to be translated
  # from legacy 16-bit format to modern 64-bit format.
  class MemoryAccessRequest
    attr_reader :legacy_selector, :legacy_offset, :access_type, :data

    # @param legacy_selector [Integer] 16-bit segment selector
    # @param legacy_offset [Integer] 16-bit offset
    # @param access_type [Symbol] :read, :write, :execute
    # @param data [Integer, nil] Data to write (for write operations)
    def initialize(legacy_selector, legacy_offset, access_type, data = nil)
      raise ArgumentError, "Selector must be 16-bit" unless (0..0xFFFF).cover?(legacy_selector)
      raise ArgumentError, "Offset must be 16-bit" unless (0..0xFFFF).cover?(legacy_offset)
      raise ArgumentError, "Invalid access type" unless VALID_ACCESS_TYPES.include?(access_type)

      @legacy_selector = legacy_selector
      @legacy_offset = legacy_offset
      @access_type = access_type
      @data = data
    end

    def to_s
      "AccessRequest(sel=0x#{format('%04X', @legacy_selector)}, off=0x#{format('%04X', @legacy_offset)}, type=#{@access_type})"
    end

    VALID_ACCESS_TYPES = [:read, :write, :execute].freeze
  end

  # Represents the result of a memory access operation.
  class MemoryAccessResult
    attr_reader :success, :translated_address, :data, :error_message

    # @param success [Boolean] Whether the operation succeeded
    # @param translated_address [Integer, nil] The modern 64-bit address
    # @param data [Integer, nil] Data read (for read operations)
    # @param error_message [String, nil] Error description if failed
    def initialize(success, translated_address = nil, data = nil, error_message = nil)
      @success = success
      @translated_address = translated_address
      @data = data
      @error_message = error_message
    end

    def to_s
      if @success
        "AccessResult(success, addr=0x#{format('%016X', @translated_address)}, data=#{@data})"
      else
        "AccessResult(failed: #{@error_message})"
      end
    end
  end
end
