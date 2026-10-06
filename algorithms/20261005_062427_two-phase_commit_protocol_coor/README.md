# Two-Phase Commit Protocol Coordinator and Participant State Machine

Core **Ruby** implementation for **Two-Phase Commit Protocol Coordinator and Participant State Machine**, structured for computational clarity, explicit data structures, and deterministic unit test coverage.

### Core Highlights
* **Language & Standard**: Modern `Ruby` standard library conventions.
* **Architecture Pattern**: Designed for `Distributed Consensus & State Machine` using `Append-Only State Log & Version Matrix`.
* **Runtime Overhead**: Contiguous memory layouts and standard collections are favored for straightforward iteration and access.
* **Concurrency & Safety**: Execution behavior is validated against nominal workflows and boundary edge cases.

---

### Complexity Analysis

| Dimension | Bound |
| :--- | :--- |
| **Time (Best Case)** | `O(1)` |
| **Time (Worst Case)** | `O(N) during sync` |
| **Auxiliary Space** | `O(N) state log` |

---

### Test Suite Execution

Self-contained verification drivers are embedded directly in `main.rb` to validate happy paths, boundary inputs, and invariant preservation.

```bash
ruby main.rb
```

---

*Source code released under the MIT License • [@myonathanlinkedin](https://github.com/myonathanlinkedin)*
