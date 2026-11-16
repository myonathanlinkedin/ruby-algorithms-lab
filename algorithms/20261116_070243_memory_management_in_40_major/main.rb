require_relative 'core'
require 'minitest/autorun'

class TestProjectMemoryInfo < Minitest::Test
  def test_valid_initialization
    info = MemorySurvey::ProjectMemoryInfo.new(
      name: 'libfoo',
      total_memory: 1024,
      heap_usage: 400,
      stack_usage: 200,
      dynamic_allocations: 50,
      static_allocations: 300
    )
    assert_instance_of MemorySurvey::ProjectMemoryInfo, info
    assert_equal 'libfoo', info.name
  end

  def test_invalid_name
    assert_raises(ArgumentError) do
      MemorySurvey::ProjectMemoryInfo.new(
        name: '',
        total_memory: 100,
        heap_usage: 30,
        stack_usage: 20,
        dynamic_allocations: 5,
        static_allocations: 40
      )
    end
  end

  def test_negative_values
    assert_raises(ArgumentError) do
      MemorySurvey::ProjectMemoryInfo.new(
        name: 'proj',
        total_memory: -10,
        heap_usage: 0,
        stack_usage: 0,
        dynamic_allocations: 0,
        static_allocations: 0
      )
    end
  end

  def test_inconsistent_totals
    assert_raises(ArgumentError) do
      MemorySurvey::ProjectMemoryInfo.new(
        name: 'proj',
        total_memory: 100,
        heap_usage: 60,
        stack_usage: 30,
        dynamic_allocations: 0,
        static_allocations: 20
      )
    end
  end
end

class TestSurvey < Minitest::Test
  def setup
    @survey = MemorySurvey::Survey.new
    @proj_a = MemorySurvey::ProjectMemoryInfo.new(
      name: 'A',
      total_memory: 800,
      heap_usage: 300,
      stack_usage: 200,
      dynamic_allocations: 20,
      static_allocations: 250
    )
    @proj_b = MemorySurvey::ProjectMemoryInfo.new(
      name: 'B',
      total_memory: 1200,
      heap_usage: 500,
      stack_usage: 400,
      dynamic_allocations: 30,
      static_allocations: 250
    )
    @proj_c = MemorySurvey::ProjectMemoryInfo.new(
      name: 'C',
      total_memory: 600,
      heap_usage: 100,
      stack_usage: 150,
      dynamic_allocations: 10,
      static_allocations: 300
    )
    @survey.add_project(@proj_a).add_project(@proj_b).add_project(@proj_c)
  end

  def test_average_total_memory
    expected = (800 + 1200 + 600).to_f / 3
    assert_in_delta expected, @survey.average_total_memory, 1e-6
  end

  def test_median_total_memory
    # Sorted totals: 600, 800, 1200 => median 800
    assert_in_delta 800.0, @survey.median_total_memory, 1e-6
  end

  def test_stddev_total_memory
    avg = @survey.average_total_memory
    variance = ((800 - avg)**2 + (1200 - avg)**2 + (600 - avg)**2) / 2
    expected = Math.sqrt(variance)
    assert_in_delta expected, @survey.stddev_total_memory, 1e-6
  end

  def test_top_n_by_heap
    top = @survey.top_n_by_heap(2)
    assert_equal 2, top.size
    assert_equal @proj_b, top[0] # 500 heap
    assert_equal @proj_a, top[1] # 300 heap
  end

  def test_dominant_allocation_distribution
    dist = @survey.dominant_allocation_distribution
    # Project A: static (250) > heap (300)?? Actually heap 300 > static 250, so heap dominant.
    # Project B: heap 500 > static 250, heap dominant.
    # Project C: static 300 > heap 100, static dominant.
    assert_equal 2, dist[:heap]
    assert_equal 1, dist[:static]
    assert_equal 0, dist[:stack] || 0
  end

  def test_summary_contains_expected_fields
    summary = @survey.summary
    assert_match /Projects surveyed: 3/, summary
    assert_match /Average total memory:/, summary
    assert_match /Dominant allocation distribution:/, summary
  end

  def test_empty_survey_edge_cases
    empty = MemorySurvey::Survey.new
    assert_nil empty.average_total_memory
    assert_nil empty.median_total_memory
    assert_nil empty.stddev_total_memory
    assert_empty empty.top_n_by_heap(3)
    assert_equal({}, empty.dominant_allocation_distribution)
  end

  def test_invalid_top_n_argument
    assert_raises(ArgumentError) { @survey.top_n_by_heap(0) }
    assert_raises(ArgumentError) { @survey.top_n_by_heap(-1) }
    assert_raises(ArgumentError) { @survey.top_n_by_heap('five') }
  end
end

# Demonstration entry point (executed when running this file directly)
if __FILE__ == $0
  puts 'Running MemorySurvey unit tests...'
  Minitest.run
end
