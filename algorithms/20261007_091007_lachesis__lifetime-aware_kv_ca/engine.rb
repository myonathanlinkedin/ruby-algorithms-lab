# frozen_string_literal: true

require_relative 'types'

# Core cache implementation with lifetime‑aware placement across HBM and DRAM
class LachesisCache
  attr_reader :hbm_capacity, :dram_capacity

  # dram_capacity may be nil (unbounded)
  def initialize(hbm_capacity:, dram_capacity: nil)
    @hbm_capacity = hbm_capacity.to_i
    @dram_capacity = dram_capacity ? dram_capacity.to_i : nil
    @hbm = {}   # key => CacheItem
    @dram = {}  # key => CacheItem
  end

  # Retrieve a value; updates access count and may promote the item
  def get(key)
    cleanup_expired!
    item = @hbm[key] || @dram[key]
    return nil unless item && item.alive?

    item.access_count += 1
    promote_if_needed(item)
    item.value
  end

  # Insert or update a key‑value pair with a given ttl (seconds)
  def put(key, value, ttl)
    cleanup_expired!
    existing = @hbm[key] || @dram[key]
    if existing
      existing.value = value
      existing.ttl = ttl.to_f
      existing.created_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      existing.access_count = 0
      existing.tier = decide_initial_tier(existing)
    else
      tier = decide_initial_tier_by_metrics(key, value, ttl)
      item = CacheItem.new(key: key, value: value, ttl: ttl, tier: tier)
      place_item(item)
    end
    true
  end

  # Expose internal state for testing
  def hbm_keys
    @hbm.keys
  end

  def dram_keys
    @dram.keys
  end

  private

  # Decide initial tier for a brand‑new item based on current load
  def decide_initial_tier_by_metrics(_key, _value, _ttl)
    if @hbm.size < @hbm_capacity
      Tier::HBM
    else
      Tier::DRAM
    end
  end

  # For updates, keep the same tier unless capacity forces a move
  def decide_initial_tier(item)
    if item.tier == Tier::HBM && @hbm.size > @hbm_capacity
      Tier::DRAM
    else
      item.tier
    end
  end

  # Insert item into appropriate tier, evicting if necessary
  def place_item(item)
    case item.tier
    when Tier::HBM
      if @hbm.size >= @hbm_capacity
        evict_from_hbm!
      end
      @hbm[item.key] = item
    when Tier::DRAM
      if @dram_capacity && @dram.size >= @dram_capacity
        evict_from_dram!
      end
      @dram[item.key] = item
    end
  end

  # Promote an item to HBM if its score justifies it
  def promote_if_needed(item)
    return if item.tier == Tier::HBM
    return unless @hbm.size < @hbm_capacity

    # Simple heuristic: promote if score exceeds the lowest HBM score
    lowest_hbm_item = @hbm.values.min_by(&:score)
    if lowest_hbm_item && item.score > lowest_hbm_item.score
      demote(lowest_hbm_item)
      move_to_hbm(item)
    end
  end

  # Demote an HBM item to DRAM (evict if DRAM full)
  def demote(item)
    @hbm.delete(item.key)
    item.tier = Tier::DRAM
    if @dram_capacity && @dram.size >= @dram_capacity
      evict_from_dram!
    end
    @dram[item.key] = item
  end

  # Move a DRAM item into HBM (assumes space is available)
  def move_to_hbm(item)
    @dram.delete(item.key)
    item.tier = Tier::HBM
    @hbm[item.key] = item
  end

  # Evict the lowest‑scoring item from HBM to DRAM
  def evict_from_hbm!
    victim = @hbm.values.min_by(&:score)
    return unless victim
    demote(victim)
  end

  # Evict the lowest‑scoring item from DRAM completely
  def evict_from_dram!
    victim = @dram.values.min_by(&:score)
    @dram.delete(victim.key) if victim
  end

  # Remove expired items from both tiers
  def cleanup_expired!
    @hbm.delete_if { |_k, v| !v.alive? }
    @dram.delete_if { |_k, v| !v.alive? }
  end
end
