module TicTacToe
  class Minimax
    MAX_SCORE = 10
    MIN_SCORE = -10

    def initialize(max_player = Board::PLAYER_X)
      @max_player = max_player
      @min_player = opposite_player(max_player)
    end

    def best_move(board, player)
      raise ArgumentError, 'Board must be non-terminal' if board.terminal?
      _, move = minimax(board, player, 0, MIN_SCORE, MAX_SCORE)
      move
    end

    private

    def opposite_player(player)
      player == Board::PLAYER_X ? Board::PLAYER_O : Board::PLAYER_X
    end

    def minimax(board, player, depth, alpha, beta)
      if board.winner == @max_player
        return [MAX_SCORE - depth, nil]
      elsif board.winner == @min_player
        return [MIN_SCORE + depth, nil]
      elsif board.full?
        return [0, nil]
      end

      best_move = nil

      if player == @max_player
        max_eval = MIN_SCORE - 1
        board.legal_moves.each do |move|
          child = board.make_move(move, player)
          eval_score, _ = minimax(child, opposite_player(player), depth + 1, alpha, beta)
          if eval_score > max_eval
            max_eval = eval_score
            best_move = move
          end
          alpha = [alpha, eval_score].max
          break if beta <= alpha
        end
        [max_eval, best_move]
      else
        min_eval = MAX_SCORE + 1
        board.legal_moves.each do |move|
          child = board.make_move(move, player)
          eval_score, _ = minimax(child, opposite_player(player), depth + 1, alpha, beta)
          if eval_score < min_eval
            min_eval = eval_score
            best_move = move
          end
          beta = [beta, eval_score].min
          break if beta <= alpha
        end
        [min_eval, best_move]
      end
    end
  end
end
