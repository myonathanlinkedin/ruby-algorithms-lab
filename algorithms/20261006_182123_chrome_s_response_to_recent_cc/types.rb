class Domain
  attr_reader :name, :tld

  def initialize(name)
    raise ArgumentError, "Domain name must be a non-empty string" unless name.is_a?(String) && !name.empty?
    @name = name.downcase
    @tld = extract_tld(@name)
  end

  private

  def extract_tld(hostname)
    parts = hostname.split('.')
    raise ArgumentError, "Invalid domain format" if parts.size < 2
    parts.last
  end
end

class HijackRegistry
  attr_reader :hijacked_tlds

  def initialize(list = [])
    @hijacked_tlds = list.map(&:downcase).uniq
  end

  def hijacked?(tld)
    @hijacked_tlds.include?(tld.downcase)
  end
end
