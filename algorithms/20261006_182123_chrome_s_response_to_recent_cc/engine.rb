require_relative 'types'

class ChromePolicy
  CACHE_SIZE = 100

  def initialize(registry)
    @registry = registry
    @cache = {}
    @cache_order = []
  end

  def evaluate(domain)
    raise ArgumentError, "Domain must be a Domain instance" unless domain.is_a?(Domain)
    cached = fetch_from_cache(domain.tld)
    return cached if cached

    result = if @registry.hijacked?(domain.tld)
               :blocked
             else
               :allowed
             end
    store_in_cache(domain.tld, result)
    result
  end

  private

  def fetch_from_cache(tld)
    @cache[tld]
  end

  def store_in_cache(tld, result)
    if @cache.key?(tld)
      @cache_order.delete(tld)
    elsif @cache.size >= CACHE_SIZE
      lru = @cache_order.shift
      @cache.delete(lru)
    end
    @cache[tld] = result
    @cache_order << tld
  end
end
