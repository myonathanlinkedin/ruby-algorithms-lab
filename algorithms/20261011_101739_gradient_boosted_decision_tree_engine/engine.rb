# Core algorithmic implementation of a tiny XGBoost‑like regressor.

require_relative 'types'

module XGBoostEngine
  # Helper methods for statistics.
  module Stats
    module_function

    def mean(samples)
      return 0.0 if samples.empty?
      samples.map(&:label).sum / samples.size.to_f
    end

    def mse(samples, value)
      return 0.0 if samples.empty?
      samples.map { |s| (s.label - value)**2 }.sum / samples.size.to_f
    end
  end

  # Simple CART regression tree builder with a configurable max depth.
  class RegressionTreeBuilder
    include Stats

    def initialize(max_depth)
      @max_depth = max_depth
    end

    def build(samples)
      raise ArgumentError, 'samples must be non‑empty' if samples.empty?
      build_recursive(samples, 0)
    end

    private

    def build_recursive(samples, depth)
      # Stopping criteria: max depth reached or pure node.
      if depth >= @max_depth || pure?(samples)
        leaf_value = mean(samples)
        return TreeNode.new(nil, nil, nil, nil, leaf_value)
      end

      best = find_best_split(samples)
      # If no valid split found, create a leaf.
      return TreeNode.new(nil, nil, nil, nil, mean(samples)) if best.nil?

      left_samples = samples.select { |s| s.features[best[:feature]] <= best[:threshold] }
      right_samples = samples.select { |s| s.features[best[:feature]] > best[:threshold] }

      left_node  = build_recursive(left_samples, depth + 1)
      right_node = build_recursive(right_samples, depth + 1)

      TreeNode.new(best[:feature], best[:threshold], left_node, right_node, nil)
    end

    def pure?(samples)
      labels = samples.map(&:label).uniq
      labels.size == 1
    end

    # Returns a hash with :feature and :threshold keys or nil if no split improves MSE.
    def find_best_split(samples)
      n_features = samples.first.features.size
      best_mse = Float::INFINITY
      best_feature = nil
      best_threshold = nil

      (0...n_features).each do |f|
        # Candidate thresholds are mid‑points between sorted unique values.
        values = samples.map { |s| s.features[f] }.uniq.sort
        next if values.size <= 1

        (0...values.size - 1).each do |i|
          threshold = (values[i] + values[i + 1]) / 2.0
          left  = samples.select { |s| s.features[f] <= threshold }
          right = samples.select { |s| s.features[f] > threshold }
          next if left.empty? || right.empty?

          left_mean  = mean(left)
          right_mean = mean(right)
          total_mse = (mse(left, left_mean) * left.size + mse(right, right_mean) * right.size) / samples.size.to_f

          if total_mse < best_mse
            best_mse = total_mse
            best_feature = f
            best_threshold = threshold
          end
        end
      end

      return nil if best_feature.nil?
      { feature: best_feature, threshold: best_threshold }
    end
  end

  # Gradient boosted regression trees (very small subset of XGBoost functionality).
  class XGBoostRegressor
    include Stats

    attr_reader :model

    def initialize(learning_rate: 0.1, max_depth: 1, n_estimators: 10)
      @learning_rate = learning_rate
      @max_depth = max_depth
      @n_estimators = n_estimators
      @model = BoostedModel.new(@learning_rate)
    end

    # Fit the model to the provided data.
    # X: Array of feature arrays, y: Array of numeric targets.
    def fit(X, y)
      validate_input!(X, y)
      data = X.each_with_index.map { |features, i| DataPoint.new(features, y[i]) }

      # Initial prediction is the global mean (equivalent to a constant base learner).
      base_pred = mean(data)
      current_pred = Array.new(y.size, base_pred)

      @n_estimators.times do
        # Compute residuals.
        residuals = y.each_with_index.map { |target, i| target - current_pred[i] }
        residual_data = X.each_with_index.map { |features, i| DataPoint.new(features, residuals[i]) }

        # Fit a regression tree to residuals.
        tree = RegressionTreeBuilder.new(@max_depth).build(residual_data)
        @model.add_tree(tree)

        # Update predictions.
        residual_pred = predict_one_by_one(X, tree)
        current_pred = current_pred.each_with_index.map do |pred, i|
          pred + @learning_rate * residual_pred[i]
        end
      end

      # Store the base prediction as the first (implicit) tree.
      @base_prediction = base_pred
      self
    end

    # Predict for a batch of feature vectors.
    def predict(X)
      validate_features!(X)
      base = Array.new(X.size, @base_prediction)
      X.each_with_index.map do |features, idx|
        agg = base[idx]
        @model.trees.each do |tree|
          agg += @learning_rate * predict_one(features, tree)
        end
        agg
      end
    end

    private

    def predict_one(features, node)
      return node.prediction if node.leaf?
      if features[node.split_feature] <= node.split_threshold
        predict_one(features, node.left)
      else
        predict_one(features, node.right)
      end
    end

    # Helper for batch prediction of a single tree (used during training).
    def predict_one_by_one(X, tree)
      X.map { |features| predict_one(features, tree) }
    end

    def validate_input!(X, y)
      raise ArgumentError, 'X and y must be arrays' unless X.is_a?(Array) && y.is_a?(Array)
      raise ArgumentError, 'X and y must have the same length' unless X.size == y.size
      raise ArgumentError, 'training data cannot be empty' if X.empty?
      X.each { |row| raise ArgumentError, 'each feature vector must be an array' unless row.is_a?(Array) }
    end

    def validate_features!(X)
      raise ArgumentError, 'X must be an array of feature arrays' unless X.is_a?(Array)
      X.each { |row| raise ArgumentError, 'each feature vector must be an array' unless row.is_a?(Array) }
    end
  end
end
