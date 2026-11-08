# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'types'
require_relative 'engine'

# Unit‑test suite exercising GeneralizedSorter across edge cases,
# random data, and custom comparators.
class TestGeneralizedSorter < Minitest::Test
  def setup
    @sorter = GeneralizedSorter.new
  end

  def test_empty_array
    assert_equal [], @sorter.sort([])
  end

  def test_single_element
    assert_equal [42], @sorter.sort([42])
  end

  def test_already_sorted
    arr = (1..100).to_a
    assert_equal arr, @sorter.sort(arr)
  end

  def test_reverse_sorted
    arr = (1..100).to_a.reverse
    assert_equal (1..100).to_a, @sorter.sort(arr)
  end

  def test_random_large
    arr = Array.new(1_000) { rand(10_000) }
    expected = arr.sort
    assert_equal expected, @sorter.sort(arr)
  end

  def test_with_duplicates
    arr = [5, 1, 3, 5, 2, 5, 1]
    assert_equal arr.sort, @sorter.sort(arr)
  end

  def test_custom_comparator_descending
    arr = %w[apple banana cherry date]
    sorted_desc = @sorter.sort(arr) { |a, b| b <=> a }
    assert_equal arr.sort.reverse, sorted_desc
  end

  def test_struct_objects_sort_by_key
    items = (0...12).map { |i| Sortable.new(key: i % 3, id: i) }
    sorted = @sorter.sort(items) { |a, b| a.key <=> b.key }
    keys = sorted.map(&:key)
    assert_equal keys.sort, keys
    # Verify that within equal keys the relative order follows the original ids
    # (Introsort is not stable, but the test ensures deterministic ordering.)
    expected_ids = items.sort_by { |it| [it.key, it.id] }.map(&:id)
    assert_equal expected_ids, sorted.map(&:id)
  end
end
