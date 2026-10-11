# Domain models for a minimal gradient boosted regression tree implementation.

class DataPoint
  attr_reader :features, :label

  def initialize(features, label)
    @features = features.freeze
    @label = label
    freeze
  end
end

# TreeNode represents a node in a regression decision tree.
# If leaf? is true, prediction holds the leaf value and split_* are nil.
class TreeNode
  attr_reader :split_feature, :split_threshold, :left, :right, :prediction

  def initialize(split_feature, split_threshold, left, right, prediction)
    @split_feature = split_feature
    @split_threshold = split_threshold
    @left = left
    @right = right
    @prediction = prediction
    freeze
  end

  def leaf?
    @prediction != nil
  end
end

# Model aggregates the ensemble of trees and the learning rate.
class BoostedModel
  attr_reader :trees, :learning_rate

  def initialize(learning_rate)
    @learning_rate = learning_rate
    @trees = []
    freeze
  end

  def add_tree(tree)
    @trees << tree
  end
end
