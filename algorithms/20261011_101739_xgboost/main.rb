# Verification driver, edge‑case assertions, and a simple demonstration.

require 'minitest/autorun'
require_relative 'engine'

class TestXGBoostRegressor < Minitest::Test
  def test_linear_relationship
    # Simple linear data: y = 2 * x + 0
    x = (1..10).map { |i| [i.to_f] }
    y = x.map { |f| 2.0 * f[0] }

    model = XGBoostEngine::XGBoostRegressor.new(learning_rate: 0.5, max_depth: 1, n_estimators: 20)
    model.fit(x, y)
    preds = model.predict(x)

    mse = preds.zip(y).map { |p, t| (p - t)**2 }.sum / y.size.to_f
    assert_operator mse, :<, 0.5, "MSE should be low for a simple linear function"
  end

  def test_constant_target
    x = Array.new(5) { [rand] }
    y = Array.new(5, 7.3)

    model = XGBoostEngine::XGBoostRegressor.new(learning_rate: 0.3, max_depth: 2, n_estimators: 5)
    model.fit(x, y)
    preds = model.predict(x)

    preds.each { |p| assert_in_delta 7.3, p, 1e-6 }
  end

  def test_single_sample
    x = [[42.0, -3.5]]
    y = [10.0]

    model = XGBoostEngine::XGBoostRegressor.new(learning_rate: 0.1, max_depth: 1, n_estimators: 3)
    model.fit(x, y)
    pred = model.predict(x).first

    assert_in_delta 10.0, pred, 1e-6
  end

  def test_empty_dataset_raises
    assert_raises(ArgumentError) { XGBoostEngine::XGBoostRegressor.new.fit([], []) }
  end

  def test_mismatched_lengths_raises
    x = [[1], [2]]
    y = [1.0]
    assert_raises(ArgumentError) { XGBoostEngine::XGBoostRegressor.new.fit(x, y) }
  end

  def test_prediction_shape
    x_train = [[0], [1], [2]]
    y_train = [0, 1, 2]
    model = XGBoostEngine::XGBoostRegressor.new.fit(x_train, y_train)

    x_test = [[3], [4], [5]]
    preds = model.predict(x_test)
    assert_equal 3, preds.size
  end
end

# Simple demonstration when the file is executed directly.
if __FILE__ == $PROGRAM_NAME
  puts "Running a quick demo on synthetic data..."
  x = (0..9).map { |i| [i.to_f] }
  y = x.map { |f| Math.sin(f[0]) }

  reg = XGBoostEngine::XGBoostRegressor.new(learning_rate: 0.3, max_depth: 2, n_estimators: 15)
  reg.fit(x, y)

  puts "Input\tActual\tPredicted"
  x.each_with_index do |features, i|
    puts "#{features[0]}\t#{y[i].round(4)}\t#{reg.predict([features]).first.round(4)}"
  end
end
