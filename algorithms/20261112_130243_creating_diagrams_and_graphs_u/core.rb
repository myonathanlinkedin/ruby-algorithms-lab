module Diagram
  # Represents a node in the graph.
  class Node
    attr_reader :id, :label

    def initialize(id, label = nil)
      @id = id.to_s
      @label = (label || id).to_s
    end
  end

  # Represents a directed edge between two nodes.
  class Edge
    attr_reader :src, :dst, :label

    def initialize(src, dst, label = nil)
      @src = src.to_s
      @dst = dst.to_s
      @label = label ? label.to_s : nil
    end
  end

  # Core graph structure with deterministic grid layout.
  class Graph
    attr_reader :nodes, :edges

    def initialize
      @nodes = {}   # id => Node
      @edges = []   # Array of Edge
    end

    # Adds a node; raises if id already exists.
    def add_node(id, label = nil)
      raise ArgumentError, "Node #{id} already exists" if @nodes.key?(id.to_s)
      @nodes[id.to_s] = Node.new(id, label)
      self
    end

    # Adds a directed edge; raises if either endpoint is missing.
    def add_edge(src, dst, label = nil)
      raise ArgumentError, "Source node #{src} missing" unless @nodes.key?(src.to_s)
      raise ArgumentError, "Destination node #{dst} missing" unless @nodes.key?(dst.to_s)
      @edges << Edge.new(src, dst, label)
      self
    end

    # Returns a deterministic grid layout.
    # Positions are { node_id => [row, col] } (0‑based).
    def grid_layout
      n = @nodes.size
      return {} if n.zero?

      cols = Math.sqrt(n).ceil
      rows = (n.to_f / cols).ceil
      layout = {}
      @nodes.keys.each_with_index do |nid, idx|
        row = idx / cols
        col = idx % cols
        layout[nid] = [row, col]
      end
      layout
    end

    # Generates HTML + CSS that renders the graph using CSS Grid.
    # The output is a self‑contained string.
    def to_html
      layout = grid_layout
      cols = layout.values.map { |_, c| c }.max.to_i + 1
      rows = layout.values.map { |r, _| r }.max.to_i + 1

      css = <<~CSS
        .diagram {
          display: grid;
          grid-template-columns: repeat(#{cols}, 1fr);
          grid-auto-rows: 100px;
          gap: 20px;
          position: relative;
        }
        .node {
          background: #f0f8ff;
          border: 2px solid #4682b4;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-family: sans-serif;
          font-size: 0.9rem;
          position: relative;
        }
        .edge {
          position: absolute;
          background: #4682b4;
          height: 2px;
          transform-origin: left center;
        }
      CSS

      html_nodes = @nodes.map do |nid, node|
        row, col = layout[nid]
        <<~DIV
          <div class="node" id="node-#{nid}" style="grid-row: #{row + 1}; grid-column: #{col + 1};">
            #{node.label}
          </div>
        DIV
      end.join("\n")

      html_edges = @edges.map do |edge|
        src_row, src_col = layout[edge.src]
        dst_row, dst_col = layout[edge.dst]

        # Compute pixel coordinates assuming each cell is 100px high + 20px gap.
        cell_h = 100 + 20
        cell_w = 100 + 20
        x1 = src_col * cell_w + cell_w / 2
        y1 = src_row * cell_h + cell_h / 2
        x2 = dst_col * cell_w + cell_w / 2
        y2 = dst_row * cell_h + cell_h / 2

        length = Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
        angle = Math.atan2(y2 - y1, x2 - x1) * 180 / Math::PI

        style = "left: #{x1}px; top: #{y1}px; width: #{length}px; transform: rotate(#{angle}deg);"
        label_html = edge.label ? "<span style=\"position:absolute; left:#{length/2}px; top:-12px; font-size:0.8rem;\">#{edge.label}</span>" : ""

        <<~DIV
          <div class="edge" style="#{style}">#{label_html}</div>
        DIV
      end.join("\n")

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
        #{css}
          </style>
        </head>
        <body>
          <div class="diagram">
        #{html_nodes}
        #{html_edges}
          </div>
        </body>
        </html>
      HTML
    end
  end
end
