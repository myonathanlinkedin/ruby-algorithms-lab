require 'minitest/autorun'
require_relative 'core'

class TestCacheStampede < Minitest::Test
  def setup
    @cache = CacheStampede.new
  end

  def test_single_thread_cache
    counter = 0
    value = @cache.get('foo') do
      counter += 1
      'bar'
    end
    assert_equal 'bar', value
    assert_equal 1, counter
    value2 = @cache.get('foo') { counter += 1; 'baz' }
    assert_equal 'bar', value2
    assert_equal 1, counter
  end

  def test_multi_thread_stampede
    counter = 0
    counter_mutex = Mutex.new
    threads = []
    10.times do
      threads << Thread.new do
        @cache.get('key') do
          counter_mutex.synchronize { counter += 1 }
          sleep 0.1
          'value'
        end
      end
    end
    threads.each(&:join)
    assert_equal 1, counter
    assert_equal 1, @cache.size
    assert_equal 'value', @cache.get('key') { 'new' }
  end

  def test_different_keys
    counter = 0
    counter_mutex = Mutex.new
    threads = []
    5.times do |i|
      threads << Thread.new do
        @cache.get("key#{i}") do
          counter_mutex.synchronize { counter += 1 }
          sleep 0.05
          "value#{i}"
        end
      end
    end
    threads.each(&:join)
    assert_equal 5, counter
    assert_equal 5, @cache.size
    5.times do |i|
      assert_equal "value#{i}", @cache.get("key#{i}") { 'new' }
    end
  end

  def test_cache_clear
    counter = 0
    @cache.get('clear') { counter += 1; 'first' }
    assert_equal 1, counter
    @cache.clear
    @cache.get('clear') { counter += 1; 'second' }
    assert_equal 2, counter
  end
end

if __FILE__ == $0
  cache = CacheStampede.new
  threads = []
  5.times do |i|
    threads << Thread.new do
      value = cache.get('demo') do
        sleep 0.2
        "demo_value_#{i}"
      end
      puts "Thread #{i} got #{value}"
    end
  end
  threads.each(&:join)
  puts "Demo finished. Cached value: #{cache.get('demo') { 'should not run' }}"
end
