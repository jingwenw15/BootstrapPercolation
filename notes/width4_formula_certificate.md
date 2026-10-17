# Width-Four Exact Formula Certificate

## Statement

For two-neighbor bootstrap percolation on the `4 x n` grid, let `E(4,n)` be
the largest size of an inclusion-minimal percolating set. The finite-state
certificate establishes

```text
E(4,4) = 5,
E(4,n) = floor((2n + 10) / 3) for n >= 5.
```

This is a computer-assisted result. The mathematical state reduction is
written in `notes/fixed_width_state_theorem.md`, and an independent semantic
checker now verifies the complete exported graph. Details and scope are in
`notes/width4_semantic_audit.md`. External review and a broader novelty review
remain before a publication claim.

The max-plus portion now has a standalone checker. It reads only integer vertex
and edge tables, recomputes forward and reverse reachability, reconstructs every
score vector from column 3 through column 22, and checks the recurrence. It does
not import the simulator or any finite-state generation code. The independent
semantic checker additionally verifies all 416,144 state/column choices,
including rejected transitions, exact starting scores, accepting states, and
the connection between semantic and arithmetic table IDs.

The related-work audit in `notes/width4_literature_check.md` found that
Gottschau's 2020 dissertation already reports the values through `n = 11` and
proves the weaker upper bound `E(4,n) <= 4n/5 + 12/5`. No checked source states
the exact all-`n` formula. The formula is therefore plausibly, but not
definitively, new.

## Static Characterization

A nonempty set `S` is stable when each cell of `S` has at most one neighbor
outside `S`. An infected set `A` percolates exactly when no stable set avoids
`A`. It is inclusion-minimal percolating exactly when, in addition, every seed
`a` has a stable witness `S` satisfying `S intersect A = {a}`.

For height four, stable sets can be scanned by columns. The frontier records
the last two seed columns, stable-set states avoiding every seed, and the
distinct future witness obligations. This produces a finite transition graph
whose edge weight is the number of seeds in the new column.

## Boundary-Core Reduction

The stationary interior graph has 26,009 states and 114,602 transitions. Only
states that can reach a valid right boundary can occur on an accepted path.
Reverse reachability from the accepting states leaves the boundary core:

```text
states = 15,150
transitions = 46,618
right-accepting states = 8,924
```

This restriction matters. The full interior graph contains a cycle of mean
weight `4/3`, but that component cannot reach a valid right boundary and cannot
contribute to `E(4,n)`.

## Recurrence Certificate

Let `v_n(s)` be the maximum number of seeds in a length-`n` prefix ending in
boundary-core state `s`, or negative infinity if `s` is unreachable. Exact
integer propagation gives

```text
v_22(s) = v_19(s) + 2
```

for every boundary-core state `s`, including matching unreachable entries.
If `T` is the stationary max-plus transition operator, then

```text
v_(n+1) = T(v_n).
```

Because max-plus transitions commute with adding a constant to every finite
entry,

```text
v_23 = T(v_22) = T(v_19 + 2) = v_20 + 2,
```

and induction yields

```text
v_(n+3) = v_n + 2 for every n >= 19.
```

Taking the maximum over right-accepting states proves

```text
E(4,n+3) = E(4,n) + 2 for every n >= 19.
```

The exact accepted values through column 22 match
`floor((2n+10)/3)` for every `n = 5..22`. The recurrence therefore proves the
formula for every `n >= 5`. The exceptional square case is `E(4,4)=5`.

## Explicit Lower-Bound Construction

Write each column as a four-bit integer from top to bottom. For every `n >= 9`,
an extremal construction consists of a short left boundary, zero or more copies
of the three-column block `[1,1,0]`, and the fixed right boundary

```text
[2,10,8,0,1,5,4].
```

Choose the left boundary by residue:

| `n mod 3` | left boundary | number of `[1,1,0]` blocks |
|----------:|---------------|----------------------------:|
| 0 | `[2,0]` | `(n-9)/3` |
| 1 | empty | `(n-7)/3` |
| 2 | `[2,0,1,0]` | `(n-11)/3` |

The repeating block contributes two seeds per three columns. After the first
copy, processing another `[1,1,0]` returns the complete frontier state to
itself, for each residue-specific left boundary. The fixed right boundary is
accepting from that state. Along with direct checks of the three base cases,
this finite loop certifies the construction for every `n >= 9`. Direct
simulation has additionally checked `n = 9..60`. Every set has
`floor((2n+10)/3)` seeds. The implementation is in
`experiments/width4_formula_constructions.jl`.

For a human-only proof, it remains to write down the stable obstruction exposed
by deleting each type of seed in the repeating block and in the three boundary
patterns. This is now a finite case analysis rather than a search problem.

## Reproduction

Generate the recurrence certificate with:

```text
julia experiments/width4_boundary_recurrence.jl \
  experiments/results/width4_boundary_recurrence.txt
```

Export the standalone weighted-graph certificate and check it with:

```text
julia experiments/width4_boundary_certificate_export.jl
julia experiments/check_width4_boundary_certificate.jl
```

To check the model-to-graph translation independently as well, run:

```text
julia experiments/check_width4_semantic_certificate.jl \
  experiments/results/width4_semantic_certificate.txt
```

This checks the entire reachable semantic graph against a separate Base Julia
implementation using ordinary sets, then invokes the arithmetic checker. It
does not trust the original exporter to have included every successor.

Generate the finite sequence through column 40 with:

```text
julia experiments/width4_eventual_periodicity.jl 40 4 \
  experiments/results/width4_graph_acceptance_4_to_40.csv
```

Run all project checks with:

```text
julia test/runtests.jl
julia experiments/verify_width4_findings.jl
```
