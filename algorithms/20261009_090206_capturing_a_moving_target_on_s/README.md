# Capturing a Moving Target on Star Graphs by Two Communicating Mobile Agents

A clean, dependency-free **Ruby** reference implementation of **Capturing a Moving Target on Star Graphs by Two Communicating Mobile Agents**, focused on core algorithmic mechanics, clear memory layout, and test verification.

### Core Highlights
* **Language & Standard**: Modern `Ruby` standard library conventions.
* **Architecture Pattern**: Designed for `Graph Topology & Traversal` using `Adjacency List & Priority Heap`.
* **Runtime Overhead**: Contiguous memory layouts and standard collections are favored for straightforward iteration and access.
* **Concurrency & Safety**: State transitions follow clear ordering guarantees with explicit validation at each phase.

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

*Source code released under the MIT License • [@myonathanlinkedin](https://github.com/myonathanlinkedin)*