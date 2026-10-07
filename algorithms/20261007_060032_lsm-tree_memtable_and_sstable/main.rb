require 'lsm_tree_engine'

RSpec.describe LSMTreeEngine do
  it 'should create LSM-Tree' do
    engine = LSMTreeEngine.new(100, 10)

    engine.add("key1", "value1")
    engine.add("key2", "value2")
    engine.add("key3", "value3")

    expect(engine.get("key1")).to eq("value1")
    expect(engine.get("key2")).to eq("value2")
    expect(engine.get("key3")).to be_nil
    expect(engine.remove("key1")).to be_nil
    expect(engine.get("key1")).to be_nil
  end
end
