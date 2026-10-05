module Iroh
  # Represents a piece of content in the discovery system.
  class ContentItem
    attr_reader :id, :title, :body, :tags, :timestamp

    def initialize(id:, title:, body:, tags: [], timestamp: Time.now)
      @id = id
      @title = title
      @body = body
      @tags = tags.map(&:downcase).uniq
      @timestamp = timestamp
    end

    # Returns an array of normalized tokens from title and body.
    def tokens
      @tokens ||= begin
        text = "#{title} #{body}"
        text.downcase.scan(/\w+/)
      end
    end
  end

  # In‑memory index supporting fast keyword and tag lookup.
  class ContentIndex
    def initialize
      @items = {}                     # id => ContentItem
      @inverted = Hash.new { |h, k| h[k] = {} } # token => {id => frequency}
      @tag_index = Hash.new { |h, k| h[k] = {} } # tag => {id => true}
    end

    # Adds or replaces a ContentItem.
    def add_item(item)
      remove_item(item.id) if @items.key?(item.id)
      @items[item.id] = item
      index_tokens(item)
      index_tags(item)
      self
    end

    # Removes an item by id.
    def remove_item(id)
      return unless @items.key?(id)

      item = @items.delete(id)
      item.tokens.each do |tok|
        @inverted[tok].delete(id)
        @inverted.delete(tok) if @inverted[tok].empty?
      end
      item.tags.each do |tag|
        @tag_index[tag].delete(id)
        @tag_index.delete(tag) if @tag_index[tag].empty?
      end
      self
    end

    # Searches for items matching the query and optional tag filters.
    # Returns up to +limit+ items sorted by relevance score.
    def search(query, tags: [], limit: 10)
      query_tokens = normalize(query)
      return [] if query_tokens.empty?

      # Gather candidate ids with token matches.
      candidate_scores = Hash.new(0)
      query_tokens.each do |tok|
        next unless @inverted.key?(tok)

        @inverted[tok].each do |id, freq|
          candidate_scores[id] += freq
        end
      end

      # Apply tag filters if any.
      unless tags.empty?
        tag_set = tags.map(&:downcase).to_set
        candidate_scores.select! do |id, _|
          (tag_set - @items[id].tags).empty?
        end
      end

      # Rank by score then recency.
      sorted = candidate_scores.sort_by do |id, score|
        [-score, -@items[id].timestamp.to_i]
      end

      sorted.first(limit).map { |id, _| @items[id] }
    end

    private

    def index_tokens(item)
      freq = Hash.new(0)
      item.tokens.each { |tok| freq[tok] += 1 }
      freq.each { |tok, count| @inverted[tok][item.id] = count }
    end

    def index_tags(item)
      item.tags.each { |tag| @tag_index[tag][item.id] = true }
    end

    def normalize(text)
      text.downcase.scan(/\w+/)
    end
  end

  # High‑level façade exposing discovery operations.
  class DiscoveryEngine
    def initialize
      @index = ContentIndex.new
    end

    def add(id:, title:, body:, tags: [], timestamp: Time.now)
      item = ContentItem.new(id: id, title: title, body: body, tags: tags, timestamp: timestamp)
      @index.add_item(item)
    end

    def remove(id)
      @index.remove_item(id)
    end

    def find(query, tags: [], limit: 10)
      @index.search(query, tags: tags, limit: limit)
    end
  end
end
