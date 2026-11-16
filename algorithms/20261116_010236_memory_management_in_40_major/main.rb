require_relative 'types'
require_relative 'engine'

# Simple assertion helper – raises RuntimeError on failure.
def assert(condition, message = 'assertion failed')
  raise RuntimeError, message unless condition
end

# ----------------------------------------------------------------------
# Demo data: a miniature survey of 8 well‑known C projects.
# ----------------------------------------------------------------------
sample_projects = [
  Types::Project.new('Linux Kernel', 27_000_000, [:manual, :custom_allocator]),
  Types::Project.new('SQLite', 500_000, [:manual]),
  Types::Project.new('Git', 2_000_000, [:manual, :reference_counting]),
  Types::Project.new('OpenSSL', 1_200_000, [:manual]),
  Types::Project.new('FFmpeg', 3_500_000, [:manual, :custom_allocator]),
  Types::Project.new('cURL', 800_000, [:manual]),
  Types::Project.new('glibc', 4_000_000, [:manual, :custom_allocator]),
  Types::Project.new('LLVM', 10_000_000, [:manual, :smart_pointers])
]

survey = Engine::Survey.new(sample_projects)

# ----------------------------------------------------------------------
# Unit‑test style assertions covering normal and edge cases.
# ----------------------------------------------------------------------
# Basic counts
assert(survey.total_projects == 8, 'total_projects should be 8')
assert(survey.count_by_strategy[:manual] == 8, 'all projects use manual allocation')
assert(survey.count_by_strategy[:custom_allocator] == 3, 'three projects use custom allocator')
assert(survey.count_by_strategy[:reference_counting] == 1, 'one project uses reference counting')
assert(survey.count_by_strategy[:smart_pointers] == 1, 'one project uses smart pointers')
assert(survey.count_by_strategy[:garbage_collection] == 0, 'no project uses GC')

# Most common strategy
most_common, count = survey.most_common_strategy
assert(most_common == :manual && count == 8, 'most common should be manual with count 8')

# Percentages (allow small floating‑point tolerance)
percentages = survey.percentage_by_strategy
assert((percentages[:manual] - 100.0).abs < 1e-9, 'manual should be 100%')
assert((percentages[:custom_allocator] - 37.5).abs < 1e-9, 'custom allocator should be 37.5%')
assert((percentages[:reference_counting] - 12.5).abs < 1e-9, 'reference counting should be 12.5%')
assert((percentages[:smart_pointers] - 12.5).abs < 1e-9, 'smart pointers should be 12.5%')
assert(percentages[:garbage_collection] == nil || percentages[:garbage_collection] == 0.0, 'GC percentage should be nil or 0')

# Projects using multiple strategies
multi = survey.projects_using_multiple_strategies
assert(multi.size == 5, 'five projects use multiple strategies')
assert(multi.map(&:name).sort == ['FFmpeg', 'Git', 'LLVM', 'Linux Kernel', 'glibc'].sort, 'multi‑strategy list mismatch')

# Find by strategy
manual_projects = survey.find_projects_by_strategy(:manual)
assert(manual_projects.size == 8, 'find manual returns all projects')
custom_projects = survey.find_projects_by_strategy('custom_allocator')
assert(custom_projects.map(&:name).sort == ['FFmpeg', 'Linux Kernel', 'glibc'].sort, 'custom allocator list mismatch')

# Edge case: empty survey
empty_survey = Engine::Survey.new
assert(empty_survey.total_projects == 0, 'empty survey total should be 0')
assert(empty_survey.most_common_strategy.nil?, 'most common on empty should be nil')
assert(empty_survey.percentage_by_strategy.empty?, 'percentage on empty should be empty hash')
assert(empty_survey.projects_using_multiple_strategies.empty?, 'multi‑strategy on empty should be empty array')
assert(empty_survey.find_projects_by_strategy(:manual).empty?, 'find on empty should be empty array')

# ----------------------------------------------------------------------
# Demonstration output (purely illustrative – not part of assertions)
# ----------------------------------------------------------------------
if __FILE__ == $0
  puts 'Survey Summary:'
  puts "Total projects surveyed: #{survey.total_projects}"
  puts 'Strategy usage counts:'
  survey.count_by_strategy.each do |strategy, cnt|
    puts "  #{strategy}: #{cnt}"
  end
  puts 'Strategy usage percentages:'
  survey.percentage_by_strategy.each do |strategy, pct|
    puts format('  %s: %.2f%%', strategy, pct)
  end
  most, cnt = survey.most_common_strategy
  puts "Most common strategy: #{most} (used by #{cnt} projects)"
  puts "Projects employing multiple strategies (#{survey.projects_using_multiple_strategies.size}):"
  survey.projects_using_multiple_strategies.each { |p| puts "  - #{p.name}" }
end
