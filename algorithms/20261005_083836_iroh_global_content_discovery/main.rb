require 'minitest/autorun'
require 'benchmark'
require_relative 'core'

class TestDiscoveryEngine < Minitest::Test
  def setup
    @engine = Iroh::DiscoveryEngine.new
    @engine.add(
      id: 1,
      title: 'Ruby Concurrency',
      body: 'Threads, fibers, and async IO in Ruby.',
      tags: %w[programming ruby concurrency]
    )
    @engine.add(
      id: 2,
      title: 'Global Content Discovery',
      body: 'Techniques for indexing and searching massive datasets.',
      tags: %w[data search indexing]
    )
    @engine.add(
      id: 3,
      title: 'Iroh Architecture',
      body: 'Design patterns for scalable content discovery platforms.',
      tags: %w[architecture scalability]
    )
  end

  def test_basic_search
    results = @engine.find('ruby')
    assert_equal 1, results.size
    assert_equal 1, results.first.id
  end

  def test_multi_token_search
    results = @engine.find('content discovery')
    ids = results.map(&:id)
    assert_includes ids, 2
    assert_includes ids, 3
  end

  def test_tag_filtering
    results = @engine.find('discovery', tags: ['architecture'])
    assert_equal 1, results.size
    assert_equal 3, results.first.id
  end

  def test_removal
    @engine.remove(2)
    results = @engine.find('discovery')
    ids = results.map(&:id)
    refute_includes ids, 2
    assert_includes ids, 3
  end

  def test_limit
    20.times do |i|
      @engine.add(
        id: 100 + i,
        title: "Sample #{i}",
        body: "Sample body #{i}",
        tags: %w[sample]
      )
    end
    results = @engine.find('sample', limit: 5)
    assert_equal 5, results.size
  end
end

if __FILE__ == $0
  puts 'Running benchmark...'
  engine = Iroh::DiscoveryEngine.new
  item_count = 50_000

  puts "Adding #{item_count} items"
  add_time = Benchmark.realtime do
    item_count.times do |i|
      engine.add(
        id: i,
        title: "Title #{i}",
        body: "Body content with some repeated words #{i} #{i % 10}",
        tags: %w[benchmark test]
      )
    end
  end
  puts format('Add time: %.3f seconds (%.2f ops/sec)', add_time, item_count / add_time)

  puts 'Running search benchmark (10 queries)'
  search_time = Benchmark.realtime do
    10.times do
      engine.find('repeated words', tags: ['test'], limit: 20)
    end
  end
  puts format('Search time: %.3f seconds (%.2f queries/sec)', search_time, 10 / search_time)
end
