# LSM-Tree MemTable and SSTable Flush Compaction Engine

Self-contained **LSM-Tree MemTable and SSTable Flush Compaction Engine** algorithmic primitive written in idiomatic **Ruby**. Built from scratch using standard library constructs with zero external dependencies.

### Core Highlights
* **Language & Standard**: Modern `Ruby` standard library conventions.
* **Architecture Pattern**: Designed for `Balanced Hierarchical Indexing` using `Node Pointers & Self-Balancing Trees`.
* **Runtime Overhead**: Contiguous memory layouts and standard collections are favored for straightforward iteration and access.
* **Concurrency & Safety**: Encapsulates state within isolated data structures, keeping logic self-contained.

---

### Complexity Analysis

| Dimension | Bound |
| :--- | :--- |
| **Time (Best Case)** | `O(1)` |
| **Time (Worst Case)** | `O(log N)` |
| **Auxiliary Space** | `O(N)` |

---

### Test Suite Execution

Self-contained verification drivers are embedded directly in `main.rb` to validate happy paths, boundary inputs, and invariant preservation.

```bash
ruby main.rb
```

---

*Source code released under the MIT License • [@myonathanlinkedin](https://github.com/myonathanlinkedin)*