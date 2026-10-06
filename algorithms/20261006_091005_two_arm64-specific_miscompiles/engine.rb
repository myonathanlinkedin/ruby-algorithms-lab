require 'types'

module Engine
  class Arm64MiscompileInducer
    def initialize(miscompiles)
      @miscompiles = miscompiles
    end

    def induce_vulnerabilities
      miscompiles.each do |miscompile|
        puts miscompile.to_s
      end
    end
  end
end
