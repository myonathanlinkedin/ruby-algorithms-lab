class HopcroftKarp
  attr_reader :graph, :pair_u, :pair_v, :dist

  def initialize(graph)
    @graph = graph
    @pair_u = {}
    @pair_v = {}
    @dist = {}
    graph.left_nodes.each { |u| @pair_u[u] = nil }
    graph.right_nodes.each { |v| @pair_v[v] = nil }
  end

  def bfs
    queue = []
    graph.left_nodes.each do |u|
      if @pair_u[u].nil?
        @dist[u] = 0
        queue << u
      else
        @dist[u] = Float::INFINITY
      end
    end
    dist_nil = Float::INFINITY
    until queue.empty?
      u = queue.shift
      if @dist[u] < dist_nil
        graph.adjacency[u].each do |v|
          pu = @pair_v[v]
          if pu.nil?
            dist_nil = @dist[u] + 1
          else
            if @dist[pu] == Float::INFINITY
              @dist[pu] = @dist[u] + 1
              queue << pu
            end
          end
        end
      end
    end
    dist_nil != Float::INFINITY
  end

  def dfs(u)
    graph.adjacency[u].each do |v|
      pu = @pair_v[v]
      if pu.nil? || (@dist[pu] == @dist[u] + 1 && dfs(pu))
        @pair_u[u] = v
        @pair_v[v] = u
        return true
      end
    end
    @dist[u] = Float::INFINITY
    false
  end

  def max_matching
    matching = 0
    while bfs
      graph.left_nodes.each do |u|
        if @pair_u[u].nil? && dfs(u)
          matching += 1
        end
      end
    end
    matching
  end

  def matching_pairs
    @pair_u.select { |_, v| !v.nil? }.map { |u, v| [u, v] }
  end
end
