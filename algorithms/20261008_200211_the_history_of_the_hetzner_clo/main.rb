require_relative 'core'
require 'minitest/autorun'

class TestNetworkStackHistory < Minitest::Test
  def setup
    @history = NetworkStackHistory.new
    @t1 = Time.utc(2020, 1, 1, 0, 0, 0)
    @t2 = Time.utc(2021, 6, 15, 12, 30, 0)
    @t3 = Time.utc(2022, 12, 31, 23, 59, 59)
    @t4 = Time.utc(2023, 5, 20, 8, 0, 0)

    @history.add_entry(@t1, ['Linux Kernel 5.4', 'Open vSwitch 2.13'])
    @history.add_entry(@t3, ['Linux Kernel 5.15', 'Open vSwitch 2.15', 'eBPF firewall'])
  end

  def test_initial_state
    assert_empty NetworkStackHistory.new.entries
    assert_empty NetworkStackHistory.new.current_state
  end

  def test_add_entry_out_of_order
    # Insert an entry between existing ones
    @history.add_entry(@t2, ['Linux Kernel 5.10', 'Open vSwitch 2.14'])
    assert_equal 3, @history.entries.size
    assert_equal ['Linux Kernel 5.10', 'Open vSwitch 2.14'], @history.state_at(@t2)
  end

  def test_state_at_before_first
    before = Time.utc(2019, 12, 31, 23, 59, 59)
    assert_empty @history.state_at(before)
  end

  def test_state_at_exact_match
    assert_equal ['Linux Kernel 5.4', 'Open vSwitch 2.13'], @history.state_at(@t1)
    assert_equal ['Linux Kernel 5.15', 'Open vSwitch 2.15', 'eBPF firewall'], @history.state_at(@t3)
  end

  def test_state_at_between_entries
    between = Time.utc(2022, 1, 1, 0, 0, 0)
    assert_equal ['Linux Kernel 5.4', 'Open vSwitch 2.13'], @history.state_at(between)
  end

  def test_current_state
    assert_equal ['Linux Kernel 5.15', 'Open vSwitch 2.15', 'eBPF firewall'], @history.current_state
  end

  def test_replace_existing_timestamp
    @history.add_entry(@t1, ['Linux Kernel 5.5'])
    assert_equal 2, @history.entries.size
    assert_equal ['Linux Kernel 5.5'], @history.state_at(@t1)
  end

  def test_invalid_arguments
    assert_raises(ArgumentError) { @history.add_entry('not a time', []) }
    assert_raises(ArgumentError) { @history.add_entry(@t4, 'not an array') }
    assert_raises(ArgumentError) { @history.state_at('not a time') }
  end
end

# Demonstration when executed directly
if __FILE__ == $0
  history = NetworkStackHistory.new
  history.add_entry(Time.utc(2020, 3, 1), ['Linux Kernel 5.4', 'Open vSwitch 2.13'])
  history.add_entry(Time.utc(2021, 9, 10), ['Linux Kernel 5.10', 'Open vSwitch 2.14'])
  history.add_entry(Time.utc(2022, 11, 5), ['Linux Kernel 5.15', 'Open vSwitch 2.15', 'eBPF firewall'])

  puts "Full timeline:"
  history.entries.each do |e|
    puts "#{e.timestamp.iso8601} => #{e.components.join(', ')}"
  end

  query = Time.utc(2021, 12, 31)
  puts "\nState as of #{query.iso8601}:"
  puts history.state_at(query).join(', ')
end
