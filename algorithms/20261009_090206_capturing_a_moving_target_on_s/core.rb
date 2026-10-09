module StarCapture
  # Recursive exploration of all possible target moves under the deterministic
  # two‑agent sweeping strategy on a star graph with +1 centre and +n leaves.
  #
  # Returns the maximum number of steps needed to capture the target when the
  # target behaves adversarially, or nil if capture is not guaranteed within
  # the supplied limit.
  #
  # Parameters
  # ----------
  # n      : Integer – number of leaves (n ≥ 2)
  # target : Symbol|Integer – current target position (:center or leaf id)
  # a_pos  : Symbol|Integer – current position of Agent A
  # b_pos  : Symbol|Integer – current position of Agent B
  # step   : Integer – current discrete time step (starting at 0)
  # limit  : Integer – maximal number of steps to explore
  #
  # Time   : O(b^d) in the worst case, but d ≤ limit and b ≤ n, and limit = 2n.
  # Space  : O(limit) recursion depth.
  def self._recurse(n, target, a_pos, b_pos, step, limit)
    # Capture check after agents have moved in the previous step.
    return step if target == a_pos || target == b_pos
    return nil if step >= limit

    # Deterministic agents' move for this step.
    leaf = (step / 2) % n + 1
    a_next = step.even? ? leaf : :center
    b_next = step.even? ? :center : leaf

    # Target's admissible moves (must stay on the graph).
    possible_targets = (target == :center) ? (1..n).to_a : [:center]

    results = possible_targets.map do |t_next|
      _recurse(n, t_next, a_next, b_next, step + 1, limit)
    end

    # If any branch evades capture within the limit, the strategy is not
    # guaranteed; propagate nil upwards.
    return nil if results.any?(&:nil?)

    # Otherwise the adversary will pick the branch that maximises capture time.
    results.max
  end

  # Public entry: worst‑case capture steps for a given star size.
  #
  # Returns the maximal number of steps required to guarantee capture when the
  # target may start on any leaf. If the strategy fails, returns nil.
  def self.worst_case_steps(n)
    raise ArgumentError, 'Star must have at least 2 leaves' if n < 2

    max_steps = 0
    (1..n).each do |start_leaf|
      steps = _recurse(n, start_leaf, :center, :center, 0, 2 * n)
      return nil if steps.nil? # strategy fails for this start
      max_steps = [max_steps, steps].max
    end
    max_steps
  end

  # Simple simulation of a concrete (possibly non‑adversarial) target path.
  # Returns the step at which capture occurs, or nil if the limit is exceeded.
  #
  # target_policy – Proc taking (current_target_position, step) and returning
  #                 the next position (must respect graph adjacency).
  def self.simulate(n, start_pos, limit, target_policy)
    a_pos = :center
    b_pos = :center
    target = start_pos

    (0...limit).each do |step|
      # Target moves first.
      target = target_policy.call(target, step)

      # Agents move according to the sweeping schedule.
      leaf = (step / 2) % n + 1
      if step.even?
        a_pos = leaf
        b_pos = :center
      else
        a_pos = :center
        b_pos = leaf
      end

      return step + 1 if target == a_pos || target == b_pos
    end
    nil
  end
end
