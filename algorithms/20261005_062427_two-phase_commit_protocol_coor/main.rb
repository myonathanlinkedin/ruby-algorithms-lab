require 'minitest/autorun'

module TwoPhaseCommit
  module State
    INIT      = :init
    PREPARED  = :prepared
    COMMITTED = :committed
    ABORTED   = :aborted
  end

  class Participant
    attr_reader :id, :state

    def initialize(id, vote = true)
      @id   = id
      @vote = vote
      @state = State::INIT
    end

    def prepare
      @state = State::PREPARED
      @vote
    end

    def commit
      @state = State::COMMITTED
    end

    def abort
      @state = State::ABORTED
    end
  end

  class Coordinator
    attr_reader :participants, :state

    def initialize(participants)
      @participants = participants
      @state = :idle
    end

    def start_transaction
      @state = :preparing
      votes = @participants.map(&:prepare)
      if votes.all?
        @state = :committing
        @participants.each(&:commit)
        @state = :committed
      else
        @state = :aborting
        @participants.each(&:abort)
        @state = :aborted
      end
    end
  end
end

class TestTwoPhaseCommit < Minitest::Test
  def test_all_commit
    p1 = TwoPhaseCommit::Participant.new(1)
    p2 = TwoPhaseCommit::Participant.new(2)
    coord = TwoPhaseCommit::Coordinator.new([p1, p2])
    coord.start_transaction
    assert_equal :committed, coord.state
    assert_equal TwoPhaseCommit::State::COMMITTED, p1.state
    assert_equal TwoPhaseCommit::State::COMMITTED, p2.state
  end

  def test_abort_on_vote
    p1 = TwoPhaseCommit::Participant.new(1)
    p2 = TwoPhaseCommit::Participant.new(2, false)
    coord = TwoPhaseCommit::Coordinator.new([p1, p2])
    coord.start_transaction
    assert_equal :aborted, coord.state
    assert_equal TwoPhaseCommit::State::ABORTED, p1.state
    assert_equal TwoPhaseCommit::State::ABORTED, p2.state
  end

  def test_participant_states
    p = TwoPhaseCommit::Participant.new(1)
    assert_equal TwoPhaseCommit::State::INIT, p.state
    p.prepare
    assert_equal TwoPhaseCommit::State::PREPARED, p.state
    p.commit
    assert_equal TwoPhaseCommit::State::COMMITTED, p.state
  end
end

# Demonstration execution block
if __FILE__ == $0
  p1 = TwoPhaseCommit::Participant.new(1)
  p2 = TwoPhaseCommit::Participant.new(2)
  coord = TwoPhaseCommit::Coordinator.new([p1, p2])
  puts "Starting transaction..."
  coord.start_transaction
  puts "Coordinator state: #{coord.state}"
  puts "Participant 1 state: #{p1.state}"
  puts "Participant 2 state: #{p2.state}"
end
