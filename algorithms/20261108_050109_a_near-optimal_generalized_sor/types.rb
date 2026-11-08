# frozen_string_literal: true

# Simple data structure used in tests to demonstrate custom objects.
# It holds a sortable key and an identifier to trace stability.
Sortable = Struct.new(:key, :id, keyword_init: true)
