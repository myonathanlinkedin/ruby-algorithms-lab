# Async Concurrency: Where does the scheduler live?

Modern **Ruby** reference architecture for **Async Concurrency: Where does the scheduler live?**. Engineered for rigorous algorithmic correctness, high throughput, and bounded memory utilization.

### Core Highlights
* **Language & Standard**: Modern `Ruby` standard library conventions.
* **Architecture Pattern**: Designed for `Algorithmic Engineering` using `Standard Memory Primitives`.
* **Runtime Overhead**: Contiguous memory layouts are favored over scattered heap allocations for optimal traversal speed.
* **Concurrency & Safety**: Designed with reentrancy and thread isolation in mind, preventing data races under parallel workloads.

---

### Complexity Analysis

| Dimension | Bound |
| :--- | :--- |
| **Time (Best Case)** | `$O(1)$` |
| **Time (Worst Case)** | `$O(N \log N)$` |
| **Auxiliary Space** | `$O(N)$` |

---

### Test Suite Execution

Self-contained verification drivers are embedded directly in `main.rb` to validate happy paths, boundary inputs, and invariant preservation.

```bash
ruby main.rb
```

---

*Curated as part of the Polyglot Systems Lab • Maintained by [@myonathanlinkedin](https://github.com/myonathanlinkedin)*