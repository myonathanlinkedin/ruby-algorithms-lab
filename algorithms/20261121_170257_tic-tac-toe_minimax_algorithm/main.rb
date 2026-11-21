require_relative 'types'
require_relative 'engine'
require 'test/unit'

module TicTacToe
  class TicTacToeTest < Test::Unit::TestCase
    def setup
      @engine = Minimax.new(Board::PLAYER_X)
    end

    def test_initial_move_prefers_center
      board = Board.new
      move = @engine.best_move(board, Board::PLAYER_X)
      assert_equal(4, move, 'First move should be center')
    end

    def test_win_in_one_move
      # X can win by placing at position 2
      cells = [
        Board::PLAYER_X, Board::PLAYER_X, Board::EMPTY,
        Board::PLAYER_O, Board::PLAYER_O, Board::EMPTY,
        Board::EMPTY,    Board::EMPTY,    Board::EMPTY
      ]
      board = Board.new(cells)
      move = @engine.best_move(board, Board::PLAYER_X)
      assert_equal(2, move, 'Should take winning move at position 2')
    end

    def test_block_opponent_win
      # O threatens win at position 8, X must block
      cells = [
        Board::PLAYER_O, Board::PLAYER_O, Board::EMPTY,
        Board::PLAYER_X, Board::PLAYER_X, Board::EMPTY,
        Board::EMPTY,    Board::EMPTY,    Board::EMPTY
      ]
      board = Board.new(cells)
      move = @engine.best_move(board, Board::PLAYER_X)
      assert_equal(2, move, 'Should block opponent at position 2')
    end

    def test_draw_when_no_win_possible
      # Board state where optimal play leads to draw
      cells = [
        Board::PLAYER_X, Board::PLAYER_O, Board::PLAYER_X,
        Board::PLAYER_X, Board::PLAYER_O, Board::EMPTY,
        Board::PLAYER_O, Board::PLAYER_X, Board::EMPTY
      ]
      board = Board.new(cells)
      move = @engine.best_move(board, Board::PLAYER_O)
      # Both remaining moves (5 or 8) lead to draw; accept either
      assert_include([5, 8], move, 'Should choose a move that results in draw')
    end

    def test_full_board_is_terminal
      cells = [
        Board::PLAYER_X, Board::PLAYER_O, Board::PLAYER_X,
        Board::PLAYER_X, Board::PLAYER_O, Board::PLAYER_O,
        Board::PLAYER_O, Board::PLAYER_X, Board::PLAYER_X
      ]
      board = Board.new(cells)
      assert_true(board.terminal?, 'Full board must be terminal')
      assert_nil(board.winner, 'Full board in this configuration is a draw')
    end
  end
end

if __FILE__ == $0
  # Running the test suite
  Test::Unit::AutoRunner.run
end
