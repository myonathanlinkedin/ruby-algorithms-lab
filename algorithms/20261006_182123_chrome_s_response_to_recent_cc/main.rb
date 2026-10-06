require_relative 'engine'
require 'minitest/autorun'

class TestChromePolicy < Minitest::Test
  def setup
    hijacked = %w[tk ml cf]
    @registry = HijackRegistry.new(hijacked)
    @policy = ChromePolicy.new(@registry)
  end

  def test_allowed_domain
    domain = Domain.new('example.com')
    assert_equal :allowed, @policy.evaluate(domain)
  end

  def test_blocked_domain
    domain = Domain.new('malicious.tk')
    assert_equal :blocked, @policy.evaluate(domain)
  end

  def test_cache_behavior
    domain1 = Domain.new('first.ml')
    domain2 = Domain.new('second.ml')
    # First evaluation stores in cache
    assert_equal :blocked, @policy.evaluate(domain1)
    # Second evaluation should hit cache (same TLD)
    assert_equal :blocked, @policy.evaluate(domain2)
  end

  def test_invalid_domain_format
    assert_raises(ArgumentError) { Domain.new('invalid') }
  end

  def test_nil_domain
    assert_raises(ArgumentError) { @policy.evaluate(nil) }
  end

  def test_case_insensitivity
    domain = Domain.new('UPPERCASE.CF')
    assert_equal :blocked, @policy.evaluate(domain)
  end

  def test_unknown_tld_not_blocked
    domain = Domain.new('unknown.xyz')
    assert_equal :allowed, @policy.evaluate(domain)
  end
end
