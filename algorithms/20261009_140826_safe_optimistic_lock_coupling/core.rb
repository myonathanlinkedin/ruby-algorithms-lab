# frozen_string_literal: true

# Node class used by OptimisticLinkedList.
# Each node carries a value, a pointer to the next node,
# a Mutex for exclusive write access, and a version counter
# that readers can validate against.
class Node
  attr_accessor :value, :next, :version
  attr_reader :lock

  def initialize(value = nil)
    @value = value
    @next = nil
    @lock = Mutex.new
    @version = 0
  end
end

# OptimisticLinkedList implements a singly‑linked list that
# supports safe optimistic reads (no lock) and writes using
# lock‑coupling with version validation.
class OptimisticLinkedList
  def initialize
    @head = Node.new # sentinel node; never holds user data
  end

  # Returns the value at the given zero‑based index.
  # Raises IndexError if the index is out of bounds.
  def get(index)
    raise IndexError, 'negative index' if index.negative?

    loop do
      pred = @head
      curr = pred.next
      i = 0

      while curr && i < index
        ver = curr.version
        nxt = curr.next
        # If version changed during read, restart.
        next if ver != curr.version

        pred = curr
        curr = nxt
        i += 1
      end

      return nil unless curr # out‑of‑bounds

      # Validate the target node hasn't changed.
      ver = curr.version
      val = curr.value
      return val if ver == curr.version
      # otherwise retry
    end
  end

  # Inserts +value+ at the given index.
  # Raises IndexError if index is out of bounds (greater than size).
  def insert(value, index)
    raise IndexError, 'negative index' if index.negative?

    loop do
      # Optimistic traversal to locate predecessor and current.
      pred = @head
      curr = pred.next
      i = 0

      while curr && i < index
        pred = curr
        curr = curr.next
        i += 1
      end

      # If index is beyond list size, abort.
      raise IndexError, 'index out of bounds' if i < index && curr.nil?

      # Acquire lock on predecessor.
      pred.lock.lock
      begin
        # Verify that predecessor still points to the same successor.
        next unless pred.next.equal?(curr)

        # Lock successor if it exists.
        if curr
          curr.lock.lock
          begin
            # Double‑check linkage after acquiring both locks.
            next unless pred.next.equal?(curr)

            new_node = Node.new(value)
            new_node.next = curr
            pred.next = new_node

            # Bump versions to invalidate stale readers.
            pred.version += 1
            curr.version += 1
          ensure
            curr.lock.unlock
          end
        else
          # Insertion at the tail.
          new_node = Node.new(value)
          pred.next = new_node
          pred.version += 1
        end
      ensure
        pred.lock.unlock
      end
      break
    end
    true
  end

  # Deletes the node at the given index and returns its value.
  # Raises IndexError if index is out of bounds.
  def delete(index)
    raise IndexError, 'negative index' if index.negative?

    loop do
      pred = @head
      curr = pred.next
      i = 0

      while curr && i < index
        pred = curr
        curr = curr.next
        i += 1
      end

      raise IndexError, 'index out of bounds' unless curr

      # Lock predecessor first, then current (lock‑coupling order).
      pred.lock.lock
      begin
        # Verify linkage before proceeding.
        next unless pred.next.equal?(curr)

        curr.lock.lock
        begin
          # Verify again after acquiring both locks.
          next unless pred.next.equal?(curr)

          removed_value = curr.value
          succ = curr.next
          pred.next = succ

          # Bump versions.
          pred.version += 1
          curr.version += 1
          succ.version += 1 if succ
          return removed_value
        ensure
          curr.lock.unlock
        end
      ensure
        pred.lock.unlock
      end
    end
  end

  # Returns an array representation of the list (for testing).
  def to_a
    arr = []
    node = @head.next
    while node
      arr << node.value
      node = node.next
    end
    arr
  end

  # Returns the current size of the list.
  def size
    count = 0
    node = @head.next
    while node
      count += 1
      node = node.next
    end
    count
  end
end
