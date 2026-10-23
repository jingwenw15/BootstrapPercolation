# A Sharp Four-Crowded-Column Theorem

Computed and checked on 2026-10-20.

Update, 2026-10-22: a direct geometric upper-bound proof and an explicit
finite sharpness certificate are now in
[width4_crowded_hand_proof.md](width4_crowded_hand_proof.md). That proof does
not rely on the state graph. The rank certificate below is retained as an
independent computational check; the infinite pumping family remains
separately computer-assisted.

## Statement

Call a column crowded if it contains at least two initially infected cells.

**Theorem.** For every positive integer `n`, every
inclusion-minimal percolating set on the open `4 x n` grid has at most four
crowded columns. The constant four is sharp, even along an infinite sequence
of widths.

This statement concerns **all** minimal percolating sets, not just those of
largest size. Its proof does not use the formula for `E(4,n)`, the max-plus
periodicity, or the maximizer-count recurrences. It uses the independently
audited semantic graph for minimal percolation and a separate integer rank
certificate.

Equivalently, all but at most four columns contain zero or one initial seed.
This does not say those exceptional columns are close to the boundary.
Splitting at them leaves at most five intervals of single-seed-or-empty columns;
this is a useful starting point for a geometric classification, not yet that
classification itself.

## Upper-Bound Proof

For `n=1,2` the number of columns is already at most two. For `n>=3`, the
complete semantic audit establishes that a seed word is minimal percolating
if and only if its first three columns reach a warm-up state and the
remaining columns follow the exported deterministic transitions to an
accepting right-boundary state. No condition of maximum size is imposed.

Restrict to the states that can reach an accepting boundary. Every prefix of
an accepted word stays in this restriction: a state left outside it could
not later accept. The restricted graph has 15,150 states and 46,618 labeled
edges. Give an edge weight one if its seed-column label is crowded, and
zero otherwise.

Independently recompute, at each warm-up state `s`, the maximum number `d(s)`
of crowded columns in any three-column prefix reaching it. Crucially, these
prefixes are **not** restricted to maximum seed count.

The checker constructs an integer function `p` on the restricted states and
checks all of the following directly:

```text
0 <= p(s) <= 4                                  for every state s;
d(s) <= p(s)                                    for every warm-up state s;
p(t) >= p(s) + 1_(column is crowded)             for every labeled edge s -> t.
```

Induction along a seed word bounds the total number of crowded columns read
so far by the current state's rank. Every accepting state has rank at most
four, proving the theorem for every width, without any assumed experimental
cutoff. The ranks have the following distribution:

| Rank | States |
|---:|---:|
| 0 | 3,914 |
| 1 | 5,410 |
| 2 | 3,312 |
| 3 | 1,644 |
| 4 | 870 |

### How the Rank Is Found

There are 9,970 strongly connected components. Every within-component edge
has weight zero. Thus a crowded column always moves to a different component,
and the condensation graph is acyclic. A longest-path calculation on that
graph, initialized by `d(s)`, gives `p`. The separate edge-by-edge inequalities
above verify the result without trusting that longest-path calculation.

There are 2,834 crowded-column edges. The maximum accepted rank is four.
Warm-up costs are obtained by dynamic programming on the literal independent
semantic transitions; a test separately enumerates all 4,096 three-column
words to check those costs.

## Sharpness and an Infinite Family

A directly verified `4 x 15` example has these seed columns:

```text
[3,0,4,0,6,0,1,0,8,0,2,0,6,0,12].
```

Bit zero is the top row. Its grid is

```text
X.....X........
X...X.....X.X..
..X.X.......X.X
........X.....X
```

Columns 1, 5, 13, and 15 are crowded. The simulator confirms percolation,
and deleting each of the twelve seeds individually prevents percolation.
This example is minimal but not largest: our separate formula gives
`E(4,15)=13`, while it has twelve seeds. Sharpness of the crowded-column
bound does not require it to maximize total seed count.

For arbitrarily long examples, concatenate

```text
L = [3,0,4]
B = [0,2,2]
R = [0,6,0,1,0,8,0,2,0,6,0,12]

L B^k R, for every k >= 1.
```

These words have width `15+3k`, `12+2k` seeds, and exactly four crowded
columns. The independent semantic transition checker confirms that the state
after `LB` returns to itself after another `B`, and that appending `R`
accepts. Induction proves minimal percolation for every `k>=1`. Tests also
check the grids by direct simulation and deletion for `k=1,...,5`.

This family is one seed below the largest size at each of its widths. It is
not a new construction attaining the exact `E(4,n)` formula.

## Reproduction and Scope

```text
julia --project=. experiments/width4_crowded_columns.jl
julia --project=. test/runtests.jl
```

The first command runs the complete semantic audit, recomputes the warm-up
costs and rank function, checks all 46,618 rank inequalities, and regenerates
`experiments/results/width4_crowded_columns.toml`. It finds a sharp witness
and pumping family, and checks their bases with the original simulator and
every seed deletion. It uses the existing `DataStructures` dependency through
that simulator. No simulation logic is changed.

Tests exhaust all directed three-vertex graphs to check the reused component
algorithm and its topological order, reject positive-weight cycles, and check
the bounded-path calculation on a synthetic graph with parallel edges.
Incorrect ranks, weights, and proposed bounds are rejected. All minimal
sets on `4 x 1` through `4 x 4` are checked by direct bootstrap closure; their
maximum crowded-column counts agree with the transfer calculation where it
applies. The sharp witness is checked seed by seed and without input mutation.

The rank argument in this note is a computer-assisted proof. The separate
geometric proof now removes that computational dependence for the upper
bound and finite sharpness example, but neither proof is Lean-formalized or
externally reviewed. The five numerical rank levels and the shared counting
polynomial still lack direct geometric interpretations.

## Priority Check

A targeted search for crowded columns, multiple-seed columns, and minimal
percolating sets did not locate this precise statement. The relevant thin-grid
arguments in [Morris (2009), Theorem 9](https://www.combinatorics.org/ojs/index.php/eljc/article/download/v16i1r2/pdf/)
were rechecked. The search also located
[Ruoxin Zhao's 2020 thesis, Section 5.3](https://mspace.lib.umanitoba.ca/bitstreams/bb0a17ca-04f4-4ea9-b027-6161333954db/download),
which surveys the largest-minimal-set problem and attributes its exact
height-at-most-three formulas to Morris. The inspected material did not
state this height-four crowded-column theorem. This is not an exhaustive
priority review and does not establish novelty; the prior Gottschau source
and citation chains still require further review specifically for this claim.
