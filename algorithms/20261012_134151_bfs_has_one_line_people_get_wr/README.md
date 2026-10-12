# BFS has one line people get wrong: where you mark a node visited (Ruby)

> Self-contained **BFS has one line people get wrong: where you mark a node visited** algorithmic primitive written in idiomatic **Ruby**. Built from scratch using standard library constructs with zero external dependencies.

## Overview & Mechanics

The implementation focuses on the core mathematical properties of **BFS has one line people get wrong: where you mark a node visited**:
* **Data Organization**: Built upon `Adjacency List & Priority Heap` to ensure predictable traversal and storage overhead.
* **Safety Invariants**: Contiguous memory layouts and standard collections are favored for straightforward iteration and access.
* **Execution Guarantees**: State consistency is verified after mutations through assertion test coverage.

## Complexity Profile

* **Time Complexity**:
  * Fast Path (Best): `O(V + E)`
  * Generalized (Avg / Worst): `O((V + E) log V)`
* **Space Footprint**: `O(V + E)` resident heap / stack overhead.

## Verification & Test Scenarios

The test suite in `main.rb` validates:
* Standard operational paths against expected outcomes.
* Extreme values and edge inputs to ensure robust failure handling.
* State stability across sequential and repeated operations.

```bash
# Execute local verification runner
ruby main.rb
```

---

*Reference implementation verified by [@myonathanlinkedin](https://github.com/myonathanlinkedin)*