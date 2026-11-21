module TicTacToe
  class Board
    PLAYER_X = :X
    PLAYER_O = :O
    EMPTY = :_

    WIN_LINES = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ].freeze

    attr_reader :cells

    def initialize(cells = nil)
      @cells = cells ? cells.dup : Array.new(9, EMPTY)
    end

    def dup
      Board.new(@cells)
    end

    def make_move(pos, player)
      raise ArgumentError, 'Invalid position' unless (0..8).include?(pos)
      raise ArgumentError, 'Cell not empty' unless @cells[pos] == EMPTY
      new_board = dup
      new_board.cells[pos] = player
      new_board
    end

    def legal_moves
      @cells.each_index.select { |i| @cells[i] == EMPTY }
    end

    def winner
      WIN_LINES.each do |line|
        a, b, c = line
        next if @cells[a] == EMPTY
        return @cells[a] if @cells[a] == @cells[b] && @cells[b] == @cells[c]
      end
      nil
    end

    def full?
      !@cells.include?(EMPTY)
    end

    def terminal?
      winner || full?
    end

    def draw?
      full? && winner.nil?
    end

    def to_s
      rows = @cells.each_slice(3).map { |row| row.map { |c| c == EMPTY ? '_' : c }.join(' ') }
      rows.join("\n")
    end
  end
end
