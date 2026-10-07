require 'lsm_tree_engine'

RSpec.describe LSMTreeEngine do
  it 'should handle flush and compaction' do
    engine = LSMTreeEngine.new(100, 10)
      engine.add("key1", "value1")
        engine.add("key2", "value2")
         engine.add("key3", "value3")
           engine.remove("key1")
            engine.remove("key2")
                    engine.remove("key3")
end
end
