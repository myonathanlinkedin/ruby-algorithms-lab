# Topological Sort with Cycle Detection in Directed Graphs

Core **Ruby** implementation for **Topological Sort with Cycle Detection in Directed Graphs**, structured for computational clarity, explicit data structures, and deterministic unit test coverage.

### Core Highlights
* **Language & Standard**: Modern `Ruby` standard library conventions.
* **Architecture Pattern**: Designed for `Graph Topology & Traversal` using `Adjacency List & Priority Heap`.
* **Runtime Overhead**: Contiguous memory layouts and standard collections are favored for straightforward iteration and access.
* **Concurrency & Safety**: Encapsulates state within isolated data structures, keeping logic self-contained.

---

### Complexity Analysis

| Dimension | Bound |
| :--- | :--- |
| **Time (Best Case)** | `O(V + E)` |
| **Time (Worst Case)** | `O(V^2)` |
| **Auxiliary Space** | `O(V + E)` |

---

### Test Suite Execution

Self-contained verification drivers are embedded directly in `main.rb` to validate happy paths, boundary inputs, and invariant preservation.

```bash
ruby main.rb
```

---

<sub>Standard Ruby reference implementation • Maintained by [@myonathanlinkedin](https://github.com/myonathanlinkedin)</sub>