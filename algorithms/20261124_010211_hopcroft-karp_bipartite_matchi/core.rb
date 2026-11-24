class HopcroftKarp
  attr_reader :n_left, :n_right, :adj, :pair_u, :pair_v, :dist

  INF = 1 << 30

  def initialize(n_left, n_right, edges = [])
    @n_left = n_left
    @n_right = n_right
    @adj = Array.new(n_left) { [] }
    edges.each do |u, v|
      raise ArgumentError, 'Invalid left vertex' unless u.between?(0, n_left - 1)
      raise ArgumentError, 'Invalid right vertex' unless v.between?(0, n_right - 1)
      @adj[u] << v
    end
    @pair_u = Array.new(n_left, nil)
    @pair_v = Array.new(n_right, nil)
    @dist = Array.new(n_left, 0)
  end

  def max_matching
    matching = 0
    while bfs
      (0...n_left).each do |u|
        if pair_u[u].nil? && dfs(u)
          matching += 1
        end
      end
    end
    matching
  end

  private

  def bfs
    queue = []
    head = 0
    (0...n_left).each do |u|
      if pair_u[u].nil?
        dist[u] = 0
        queue << u
      else
        dist[u] = INF
      end
    end
    found = false
    while head < queue.size
      u = queue[head]
      head += 1
      adj[u].each do |v|
        pu = pair_v[v]
        if pu.nil?
          found = true
        elsif dist[pu] == INF
          dist[pu] = dist[u] + 1
          queue << pu
        end
      end
    end
    found
  end

  def dfs(u)
    adj[u].each do |v|
      pu = pair_v[v]
      if pu.nil? || (dist[pu] == dist[u] + 1 && dfs(pu))
        pair_u[u] = v
        pair_v[v] = u
        return true
      end
    end
    dist[u] = INF
    false
  end
end
