module LSMTree
  class MemTable
    attr_accessor :data

    def initialize
      @data = {}
    end

    def put(key, value)
      @data[key] = value
    end

    def get(key)
      @data[key]
    end

    def clear
      @data.clear
    end
  end

  class SSTable
    attr_accessor :data

    def initialize(filename)
      @data = {}
      File.open(filename, "w") do |file|
        file.write("Table created")
      end
    end

    def put(key, value)
      @data[key] = value
    end

    def get(key)
      @data[key]
    end

    def clear
      @data.clear
    end
  end
end
