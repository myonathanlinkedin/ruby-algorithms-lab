# Lachesis: Lifetime-Aware KV Cache Placement for Agent Serving across HBM and (Ruby)

> A clean, dependency-free **Ruby** reference implementation of **Lachesis: Lifetime-Aware KV Cache Placement for Agent Serving across HBM and**, focused on core algorithmic mechanics, clear memory layout, and test verification.

## Overview & Mechanics

The implementation focuses on the core mathematical properties of **Lachesis: Lifetime-Aware KV Cache Placement for Agent Serving across HBM and**:
* **Data Organization**: Built upon `Standard Memory Primitives` to ensure predictable traversal and storage overhead.
* **Safety Invariants**: Memory allocations are kept minimal to maintain clear data locality and predictable memory bounds.
* **Execution Guarantees**: State transitions follow clear ordering guarantees with explicit validation at each phase.

## Complexity Profile

* **Time Complexity**:
  * Fast Path (Best): `O(1)`
  * Generalized (Avg / Worst): `O(N)`
* **Space Footprint**: `O(N)` resident heap / stack overhead.

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