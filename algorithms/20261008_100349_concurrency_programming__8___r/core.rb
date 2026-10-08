class ReadWriteLock
  def initialize
    @mutex = Mutex.new
    @readers = 0
    @writer = false
    @waiting_writers = 0
    @read_cv = ConditionVariable.new
    @write_cv = ConditionVariable.new
  end

  # Acquire a read lock. Multiple readers may hold the lock simultaneously
  # unless a writer is active or waiting (writer‑priority policy).
  def read_lock
    @mutex.synchronize do
      while @writer || @waiting_writers > 0
        @read_cv.wait(@mutex)
      end
      @readers += 1
    end
    self
  end

  # Release a previously acquired read lock.
  def read_unlock
    @mutex.synchronize do
      @readers -= 1
      if @readers.zero? && @waiting_writers > 0
        @write_cv.signal
      end
    end
  end

  # Acquire a write lock. Only one writer may hold the lock and no readers
  # may be active.
  def write_lock
    @mutex.synchronize do
      @waiting_writers += 1
      while @writer || @readers > 0
        @write_cv.wait(@mutex)
      end
      @waiting_writers -= 1
      @writer = true
    end
    self
  end

  # Release a previously acquired write lock.
  def write_unlock
    @mutex.synchronize do
      @writer = false
      if @waiting_writers > 0
        @write_cv.signal
      else
        @read_cv.broadcast
      end
    end
  end

  # Block form for reading.
  def read
    read_lock
    begin
      yield
    ensure
      read_unlock
    end
  end

  # Block form for writing.
  def write
    write_lock
    begin
      yield
    ensure
      write_unlock
    end
  end
end
