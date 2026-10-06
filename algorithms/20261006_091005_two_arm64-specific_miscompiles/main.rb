require 'types'
require 'engine'

class Arm64Vulnerabilities
  include Engine

  def initialize
    @miscompiles = [
      Types::Arm64Miscompile.new('Vulnerability', 'Induces a vulnerability in curl'),
      Types::Arm64Miscompile.new('Vulnerability', 'Induces a vulnerability in libc')
    ]
  end

  def generate_vulnerabilities
    miscompiles.each do |miscompile|
      puts miscompile.to_s
    end
  end
end

# Usage example:
#
# arm64_vulnerabilities = Arm64Vulnerabilities.new
# arm64_vulnerabilities.generate_vulnerabilities
# Output:
# Arm64 Miscompile: Vulnerability: Induces a vulnerability in curl
# Arm64 Miscompile: Vulnerability: Induces a vulnerability in libc
