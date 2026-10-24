module SelfHealing
  class ParseError < StandardError; end

  class ExpressionEvaluator
    OPERATORS = {
      '+' => { precedence: 1, assoc: :left,  arity: 2 },
      '-' => { precedence: 1, assoc: :left,  arity: 2 },
      '*' => { precedence: 2, assoc: :left,  arity: 2 },
      '/' => { precedence: 2, assoc: :left,  arity: 2 }
    }.freeze

    # Public entry point
    def evaluate(expr)
      expr = expr.strip
      tokens = tokenize(expr)
      rpn = shunting_yard(tokens)
      compute_rpn(rpn)
    rescue ParseError, ZeroDivisionError => e
      # Attempt self‑healing once
      healed = self_heal(expr)
      raise e if healed == expr # no change, re‑raise original error
      evaluate(healed)
    end

    private

    # Tokenize the expression into numbers, operators and parentheses
    def tokenize(str)
      tokens = []
      i = 0
      while i < str.length
        case str[i]
        when ' ', "\t", "\n", "\r"
          i += 1
        when /[0-9.]/
          num = ''
          dot_seen = false
          while i < str.length && str[i] =~ /[0-9.]/
            if str[i] == '.'
              raise ParseError, "Multiple decimal points in number" if dot_seen
              dot_seen = true
            end
            num << str[i]
            i += 1
          end
          raise ParseError, "Invalid number '#{num}'" if num == '.' || num.end_with?('.')
          tokens << num.to_f
        when '+', '-', '*', '/', '(', ')'
          tokens << str[i]
          i += 1
        else
          raise ParseError, "Invalid character '#{str[i]}'"
        end
      end
      tokens
    end

    # Convert infix tokens to Reverse Polish Notation using the shunting‑yard algorithm
    def shunting_yard(tokens)
      output = []
      stack = []
      tokens.each do |tok|
        if tok.is_a?(Numeric)
          output << tok
        elsif OPERATORS.key?(tok)
          while (op = stack.last) && OPERATORS.key?(op) &&
                ((OPERATORS[tok][:assoc] == :left && OPERATORS[tok][:precedence] <= OPERATORS[op][:precedence]) ||
                 (OPERATORS[tok][:assoc] == :right && OPERATORS[tok][:precedence] < OPERATORS[op][:precedence]))
            output << stack.pop
          end
          stack << tok
        elsif tok == '('
          stack << tok
        elsif tok == ')'
          until stack.empty? || stack.last == '('
            output << stack.pop
          end
          raise ParseError, "Mismatched parentheses" if stack.empty?
          stack.pop # discard '('
        else
          raise ParseError, "Unknown token #{tok.inspect}"
        end
      end
      until stack.empty?
        raise ParseError, "Mismatched parentheses" if %w[( )].include?(stack.last)
        output << stack.pop
      end
      output
    end

    # Evaluate the RPN expression
    def compute_rpn(rpn)
      stack = []
      rpn.each do |tok|
        if tok.is_a?(Numeric)
          stack << tok
        else
          arity = OPERATORS[tok][:arity]
          raise ParseError, "Insufficient operands for '#{tok}'" if stack.size < arity
          b = stack.pop
          a = stack.pop
          result = case tok
                   when '+' then a + b
                   when '-' then a - b
                   when '*' then a * b
                   when '/' then raise ZeroDivisionError, "division by zero" if b.zero?
                             a / b
                   end
          stack << result
        end
      end
      raise ParseError, "Extra operands after evaluation" if stack.size != 1
      stack.first
    end

    # Heuristic self‑healing: balance parentheses, insert implicit multiplication, insert missing operators
    def self_heal(expr)
      healed = expr.dup

      # 1. Insert '*' for implicit multiplication (e.g., 2(3) or )( )
      healed.gsub!(/(?<=\d|\))(?=\()/, '*')
      healed.gsub!(/(?<=\))(?=\d)/, '*')

      # 2. Insert '+' between adjacent numbers separated by whitespace
      healed.gsub!(/(?<=\d)\s+(?=\d)/, '+')

      # 3. Balance parentheses
      open = healed.count('(')
      close = healed.count(')')
      if open > close
        healed << ')' * (open - close)
      elsif close > open
        healed = '(' * (close - open) + healed
      end

      healed
    end
  end
end
