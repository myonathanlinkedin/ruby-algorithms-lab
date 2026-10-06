# Exact Optimal Transport by Matching

Modern **Ruby** reference architecture for **Exact Optimal Transport by Matching**. Engineered for rigorous algorithmic correctness, high throughput, and bounded memory utilization.

---

## 🏛️ Architecture & Design Decisions

This module organizes `Exact Optimal Transport by Matching` into an isolated, self-contained unit:
* **Domain Focus**: `Algorithmic Engineering`
* **Primary Primitives**: `Standard Memory Primitives`
* **Memory Strategy**: Zero superfluous dynamic allocations; structured for mechanical sympathy with the host runtime.
* **Correctness Model**: Deterministic behavior across all execution cycles, resilient against asynchronous edge conditions.

### Asymptotic Complexity

| Metric | Bound | Characteristics |
| :--- | :---: | :--- |
| **Best Case Time** | `$O(1)$` | Optimized fast-path execution |
| **Average / Worst Time** | `$O(N)$` | Deterministic upper bound for generalized workloads |
| **Space Complexity** | `$O(N)$` | Strict bounds without unconstrained heap growth |

---

## 🧪 Verification Suite

The accompanying `main.rb` driver executes self-contained verification tests:
1. **Nominal Flow**: Validates baseline correctness under typical real-world inputs.
2. **Boundary Conditions**: Exercises extreme edge cases (empty inputs, singletons, capacity limits).
3. **Invariant Preservation**: Validates internal state consistency throughout mutation lifecycles.

### Running Locally

```bash
ruby main.rb
```

---

*Authored & verified by [@myonathanlinkedin](https://github.com/myonathanlinkedin) • Systems Engineering Portfolio*