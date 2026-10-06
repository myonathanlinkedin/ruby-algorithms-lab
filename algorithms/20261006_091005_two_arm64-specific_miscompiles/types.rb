module Types
  class Arm64Miscompile
    attr_reader :type

    def initialize(type)
      @type = type
    end

    def to_s
      "Arm64 #{type}"
    end
  end

  class Vulnerability
    attr_reader :type, :description

    def initialize(type, description)
      @type = type
      @description = description
    end

    def to_s
      "Vulnerability #{@type}: #{@description}"
    end
  end
end
