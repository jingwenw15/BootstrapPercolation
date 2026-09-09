# Research Plan: Maximal Minimal Percolating Sets

## Primary Question

Study 2-neighbor bootstrap percolation on the finite square grid `[n] x [n]`.
For an initially infected set `A`, infection is permanent and an uninfected cell
becomes infected in the next synchronous round once at least two of its four
orthogonal neighbors are infected.

The main object is

```text
E(n) = max {|A| : A is an inclusion-minimal percolating set in [n] x [n]}.
```

Here `A` is inclusion-minimal percolating if:

1. `A` eventually infects the entire grid, and
2. for every initially infected cell `x in A`, the set `A \ {x}` does not
   percolate.

The immediate computational goal is to compute exact small values of `E(n)`,
classify the maximizing sets, and look for structural patterns that suggest
larger constructions or sharper upper-bound arguments.

## Why This Question Is Natural

Minimum-size percolating sets are a classical extremal problem. For the
2-neighbor process on `[n] x [n]`, a diagonal gives a percolating set of size
`n`, and this minimum-size direction is well understood.

The maximum size of an inclusion-minimal percolating set is different. These
sets are large but fragile: every seed is essential, even though the set may
contain many seeds. This is the problem studied by Morris in response to a
question of Bollobas.

Known asymptotic bounds for the square-grid 2-neighbor problem are:

```text
4n^2 / 33 + o(n^2) <= E(n) <= (n + 2)^2 / 6.
```

These bounds leave a constant-factor gap. The project should use exact
small-`n` data and structural classification to search for evidence about the
right asymptotic density and possible extremal constructions.

Reference:

- Robert Morris, "Minimal percolating sets in bootstrap percolation",
  Electronic Journal of Combinatorics, 2009.
  https://arxiv.org/abs/math/0702370

## Current Baseline

The current exhaustive enumeration code computes exact values for `n = 2, 3, 4`.
The saved report is `experiments/small_n_results.txt`.

| n | configurations searched | minimal-percolating sets | E(n) | maximizers |
|---|------------------------:|-------------------------:|-----:|-----------:|
| 2 | 16                      | 2                        | 2    | 2          |
| 3 | 512                     | 23                       | 4    | 9          |
| 4 | 65,536                  | 490                      | 5    | 360        |

The report also verifies every listed maximizer by checking that removing any
single initially infected cell destroys percolation.

## Near-Term Research Questions

### 1. Symmetry Classification

The raw maximizer count is not the number of genuinely different examples.
The next step is to quotient by the 8 symmetries of the square grid:

- identity
- rotations by 90, 180, and 270 degrees
- reflection across a vertical axis
- reflection across a horizontal axis
- reflection across the main diagonal
- reflection across the anti-diagonal

Questions:

- How many symmetry classes of maximizers exist for `n = 2, 3, 4`?
- Do the representatives reveal recurring geometric motifs?
- Are the `n = 4` maximizers mostly variants of a small number of types?

### 2. Exact Search For n = 5

Plain exhaustive search over `2^25` configurations is possible in principle but
large enough to deserve careful staging. The next exact search should remain
mathematically simple:

- enumerate by infected-set size, preferably descending;
- test percolation and single-removal minimality;
- stop only once all larger sizes have been ruled out;
- use symmetry reduction only after the baseline version is trusted.

No SAT, ILP, parallel search, or probabilistic heuristics should be introduced
until the simple exact search has been benchmarked.

### 3. Structural Features

For every maximizer or symmetry-class representative, compute:

- row and column seed counts;
- connected components of the initially infected set;
- infection-time matrix;
- stabilization time;
- cells whose infection depends on each seed-removal failure.

The goal is to identify candidate "gadgets" or repeating blocks.

### 4. Percolation Time Among Minimal Sets

A related extremal quantity is

```text
T_minimal(n) = max {T(A) : A is inclusion-minimal percolating in [n] x [n]}.
```

This is distinct from maximizing time over all percolating sets. Maximum-time
questions are an active theme in bootstrap percolation. For example, Benevides
and Przykucki proved that the maximum percolation time over all percolating
sets on the `n x n` grid is `13n^2 / 18 + O(n)`.

Reference:

- Fabricio Benevides and Michal Przykucki, "Maximum percolation time in
  two-dimensional bootstrap percolation", SIAM Journal on Discrete Mathematics,
  2015. https://doi.org/10.1137/130941584

### 5. Rectangular Grids

Define the rectangular analogue

```text
E(m, n) = max {|A| : A is inclusion-minimal percolating in [m] x [n]}.
```

Rectangles may expose boundary effects and recursive constructions more clearly
than squares.

## Stage Plan

### Stage 1: Research Framing

Create this note, record the current exact baseline, and identify the immediate
research direction.

Status: complete.

### Stage 2: Symmetry Reduction

Implement grid symmetries and canonical representatives. Report the number of
symmetry classes among the current maximizers for `n = 2, 3, 4`.

Expected artifact:

- `experiments/symmetry.jl`
- additional tests in `test/runtests.jl`
- a symmetry-class report

Status: complete.

Results:

| n | raw maximizers | symmetry classes | class sizes |
|---|---------------:|-----------------:|-------------|
| 2 | 2              | 1                | 2           |
| 3 | 9              | 3                | 4, 4, 1     |
| 4 | 360            | 48               | forty-two classes of size 8; six classes of size 4 |

The full representative list is saved in
`experiments/results/symmetry_classes.txt`.

### Stage 3: Exact Search For n = 5

Add a size-ordered exact search. Benchmark it on `n = 4`, then attempt `n = 5`.

Expected artifact:

- `experiments/search_exact.jl`
- exact `E(5)` if feasible, otherwise a bottleneck report

Status: complete.

The search uses Morris's upper bound

```text
E(n) <= floor((n + 2)^2 / 6)
```

as the starting size, then checks candidate sizes in descending order. For
`n = 5`, this starts at size `8`. The computation checked all `C(25, 8)`
size-8 configurations and all `C(25, 7)` size-7 configurations.

Results:

| n | upper size checked first | configurations checked | E(n) | raw maximizers | symmetry classes |
|---|-------------------------:|-----------------------:|-----:|---------------:|-----------------:|
| 5 | 8                        | 1,562,275              | 7    | 88             | 11               |

All 88 maximizers pass the single-removal verification. The full exact-search
report is saved in `experiments/results/exact_search_n5.txt`; the
symmetry-reduced representatives are saved in
`experiments/results/symmetry_classes_n5.txt`.

### Stage 4: Feature Extraction

Compute structural statistics for maximizers and symmetry-class representatives.

Expected artifact:

- `experiments/features.jl`
- machine-readable summaries under `experiments/results/`

Preliminary Stage 4A status: rectangular exact table complete for
`2 <= m <= n <= 5`, with selected additional cases `2 x 6`, `3 x 6`, and
`4 x 6`. See `notes/rectangle_findings.md`.

### Stage 5: Conjecture Note

Summarize observed sequences, densities, representative configurations, and
candidate conjectures.

Expected artifact:

- `notes/conjectures.md`

## Immediate Next Action

Proceed to Stage 2: symmetry reduction and classification of the already
computed maximizers.
