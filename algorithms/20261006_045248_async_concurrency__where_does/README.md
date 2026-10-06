# Async Concurrency: Where does the scheduler live?

Core **Ruby** implementation for **Async Concurrency: Where does the scheduler live?**, structured for computational clarity, explicit data structures, and deterministic unit test coverage.

### Core Highlights
* **Language & Standard**: Modern `Ruby` standard library conventions.
* **Architecture Pattern**: Designed for `Algorithmic Engineering` using `Standard Memory Primitives`.
* **Runtime Overhead**: Contiguous memory layouts and standard collections are favored for straightforward iteration and access.
* **Concurrency & Safety**: Encapsulates state within isolated data structures, keeping logic self-contained.

---

### Complexity Analysis

| Dimension | Bound |
| :--- | :--- |
| **Time (Best Case)** | `O(1)` |
| **Time (Worst Case)** | `O(N log N)` |
| **Auxiliary Space** | `O(N)` |

---

### Test Suite Execution

Self-contained verification drivers are embedded directly in `main.rb` to validate happy paths, boundary inputs, and invariant preservation.

```bash
ruby main.rb
```

---

*Part of the Polyglot Systems Lab • Maintained by [@myonathanlinkedin](https://github.com/myonathanlinkedin)*
