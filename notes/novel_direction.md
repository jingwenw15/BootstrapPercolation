# Most Reasonable Novel Direction

The most promising direction is not a closed formula yet. The data now points
to a more concrete phenomenon:

```text
width 4 has a rigidity-to-flexibility transition between n = 7 and n = 8.
```

## Certified Width-4 Values

Exact search gives:

| n | Morris upper start | E(4,n) | gap | raw maximizers | rectangle symmetry classes |
|---|-------------------:|-------:|----:|---------------:|---------------------------:|
| 4 | 6  | 5 | 1 | 360   | 90   |
| 5 | 7  | 6 | 1 | 280   | 73   |
| 6 | 8  | 7 | 1 | 40    | 10   |
| 7 | 9  | 8 | 1 | 2     | 1    |
| 8 | 10 | 8 | 2 | 7,074 | 1,778 |

The `4 x 8` value disproves two simple guesses:

```text
E(4,n) = n + 1
```

and

```text
E(m,n) is always Morris's upper bound or one below it.
```

## Main Observation

The transition from `4 x 7` to `4 x 8` is abrupt:

- `4 x 7`: exactly 2 raw maximizers, one class up to row/column reversal.
- `4 x 8`: 7,074 raw maximizers, 1,778 classes up to row/column reversal.

At the same time, the maximum size does not increase:

```text
E(4,7) = 8
E(4,8) = 8
```

So adding an eighth column creates many more extremal configurations but does
not allow one more seed in a minimal percolating set.

## Why This May Be Novel

Morris's exact thin-rectangle formulas cover dimensions `1`, `2`, and `3`, but
not width `4`. A targeted search did not find an existing exact formula for
`E(4,n)` or a discussion of this `4 x 7` to `4 x 8` transition.

This does not prove novelty. It identifies a plausible new computational
phenomenon worth investigating.

## Better Research Question

Instead of trying to guess a full formula for `E(4,n)` immediately, ask:

```text
Why is E(4,8) = E(4,7), even though the number of extremal configurations
explodes?
```

More specifically:

1. What structural obstruction rules out size-9 minimal percolating sets on
   `4 x 8`?
2. Why is the `4 x 7` extremal configuration essentially unique?
3. What new degrees of freedom appear at `4 x 8` while keeping the same maximum
   size?
4. Does the next value satisfy `E(4,9) = 9`, or does the plateau continue?

## Next Practical Step

The most valuable next computation is not a full `4 x 9` brute force. It is to
analyze the failed size-9 candidates for `4 x 8`.

Potential target:

```text
classify why every size-9 percolating set on 4 x 8 is not inclusion-minimal,
or why every size-9 minimal set fails to percolate.
```

That could lead to a proof of the exact value `E(4,8) = 8` that does not rely
on exhaustive enumeration.

## Size-9 Obstruction Data

The size-9 layer of `4 x 8` was classified exactly.

```text
total size-9 sets:      28,048,800
percolating:             9,564,940
nonpercolating:         18,483,860
minimal percolating:             0
```

So size 9 fails for two different reasons:

1. most size-9 sets do not percolate;
2. every size-9 set that does percolate has at least one removable seed.

Among the percolating size-9 sets, the number of removable seeds is distributed
as follows:

| removable seeds | count |
|----------------:|------:|
| 1 | 240 |
| 2 | 28,964 |
| 3 | 347,580 |
| 4 | 1,592,912 |
| 5 | 3,106,772 |
| 6 | 2,959,324 |
| 7 | 1,347,784 |
| 8 | 181,364 |

The rarest and most important cases are the 240 percolating size-9 sets with
exactly one removable seed. A structural proof of `E(4,8) = 8` can focus on
showing that any size-9 percolating set must contain at least one redundant
seed.

The full obstruction report is saved in
`experiments/results/width4_4x8_size9_obstruction.txt`.

## Critical Percolating Size-9 Sets

The rarest obstruction cases are the 240 size-9 sets that percolate and have
exactly one removable seed. These reduce to 60 classes under row reversal and
column reversal.

The unique removable seed is highly constrained. By symmetry-class orbit, its
possible positions occur with the following frequencies:

| removable-seed orbit | classes |
|----------------------|--------:|
| `(2,2), (2,7), (3,2), (3,7)` | 38 |
| `(2,4), (2,5), (3,4), (3,5)` | 12 |
| `(1,2), (1,7), (4,2), (4,7)` | 4 |
| `(2,1), (2,8), (3,1), (3,8)` | 3 |
| `(1,4), (1,5), (4,4), (4,5)` | 2 |
| `(1,3), (1,6), (4,3), (4,6)` | 1 |

Thus 50 of the 60 critical classes have their unique removable seed in one of
two interior row-orbits:

```text
(2,2)/(2,7)/(3,2)/(3,7)
(2,4)/(2,5)/(3,4)/(3,5)
```

This suggests that a structural proof may be possible by showing that any
size-9 percolating set on `4 x 8` must create a redundant seed in one of a few
central/boundary trigger positions.

The full classification is saved in
`experiments/results/width4_4x8_critical_size9_sets.txt`.

A compact invariant summary is saved in
`experiments/results/width4_4x8_critical_summary.txt`.

The row-profile and column-profile data do not collapse the 60 classes into just
a few types. The removable-seed orbit is the strongest organizing invariant:
38 of 60 classes are in orbit `r2c2`, and another 12 are in orbit `r2c4`.
Therefore a proof should probably condition first on where the redundant seed
must appear, rather than trying to classify by row or column counts alone.

One stronger pattern emerged from the critical dynamics: in all 240 critical
cases, the unique removable seed is reinfected at time 1 after removal. So the
redundant seed is locally forced by two infected neighbors already present
without it.

The tempting stronger statement that every size-9 percolating set has such a
locally forced seed is false: 3,206,768 percolating size-9 sets have no initially
infected seed with two initially infected neighbors. Therefore the proof must
first explain why the non-critical cases have removable seeds by another
mechanism, then handle the 240 critical cases using the local-forcing structure.

## Smarter Exact Search and `4 x 9`

The search was extended with two exact pruning steps.

First, a minimal percolating set cannot contain an initially infected seed that
already has two infected neighbors in the initial set. If such a seed is removed,
it is reinfected at time 1, after which the process follows the original
percolating trajectory. Therefore all candidates with such a locally forced seed
can be skipped without changing the answer.

Equivalently, the initially infected cells in any minimal candidate induce a
subgraph of maximum degree at most 1 in the grid graph. The generated search now
constructs only those candidates directly.

Second, for rectangular grids, the search quotients by row reversal and column
reversal. It checks only canonical representatives, but still counts raw
maximizers by multiplying by the representative orbit size.

This makes the next width-4 case feasible.

For `4 x 9`, the Morris upper bound is 11. The exact generated search gives:

| size | locally viable candidates | canonical representatives | minimal percolating |
|-----:|--------------------------:|--------------------------:|--------------------:|
| 11 | 50,749,182 | not quotient-counted in this run | 0 |
| 10 | 41,584,711 | 10,399,116 | 0 |
| 9 | 26,052,056 | 6,514,093 | 1,312 |

Thus the computation certifies:

```text
E(4,9) = 9
```

There are 1,312 raw maximizers, falling into 328 classes under row and column
reversal. Representative grids are saved in
`experiments/results/fast_exact_4x9_maximizers.txt`.

The current width-4 exact sequence is therefore:

| n | Morris upper bound | E(4,n) | gap |
|--:|-------------------:|-------:|----:|
| 4 | 6 | 5 | 1 |
| 5 | 7 | 6 | 1 |
| 6 | 8 | 7 | 1 |
| 7 | 9 | 8 | 1 |
| 8 | 10 | 8 | 2 |
| 9 | 11 | 9 | 2 |
| 10 | 12 | 10 | 2 |
| 11 | 13 | 10 | 3 |

This suggests a sharper width-4 problem than the original square-grid baseline:
determine whether the gap-2 behavior persists, grows, or becomes periodic for
`E(4,n)`.

## Exact `4 x 10` Certificate

The exact top-layer search for `4 x 10`, size 12, was too slow with the current
global subset generator. This marks a real algorithmic boundary: local pruning
and rectangle symmetries are enough for `4 x 9`, but probably not enough for a
systematic width-4 sequence.

As a construction probe, an extension search was added in
`experiments/extend_width4.jl`. It starts from the exact `4 x 9` maximizers,
inserts one empty column in every possible position, and then tries to add one
or two seeds while preserving minimal percolation.

The search found no size-11 extension of this type, but it did find a size-10
minimal percolating set on `4 x 10`:

```text
X X . . . . . X X .
. . . X X . . . . .
. . . . . . . . X X
. . . . X X . . . .
```

The merged-state DP later certified the matching upper bound. It found:

| size | raw minimal percolating sets |
|-----:|-----------------------------:|
| 12 | 0 |
| 11 | 0 |
| 10 | 82 |

Therefore:

```text
E(4,10) = 10
```

This was consistent with the conjectural pattern:

```text
E(4,n) = n for n >= 8.
```

However, the next merged-state computation disproves that simple pattern:

```text
E(4,11) = 10.
```

A first column-transfer prototype confirms the scale of the remaining problem.
It generates the same locally viable candidates as the global generator, but can
also count them by dynamic programming without materializing masks. For `4 x 10`
the locally viable layer sizes are:

| size | locally viable candidates |
|-----:|--------------------------:|
| 12 | 388,350,293 |
| 11 | 309,117,476 |
| 10 | 192,959,628 |

These counts explained why a merged-state DP was needed: generating candidates
in a cleaner order was not enough.

## Static Stable-Set Reformulation

A better exact program should use the dual obstruction to percolation.

Call a nonempty set `S` of cells stable if every cell in `S` has at most one
orthogonal neighbor outside `S`. If `S` is initially uninfected, then no cell of
`S` can ever become infected, even if every cell outside `S` eventually becomes
infected.

Therefore, for an initial infected set `A`:

```text
A percolates
iff there is no nonempty stable set S with S cap A = empty.
```

Minimality also has a static certificate. Since `A` percolates, removing a seed
`a` makes the set fail to percolate exactly when the new uninfected set contains
a stable obstruction. Such an obstruction must contain `a` and no other seed of
`A`. Thus:

```text
A is minimal percolating
iff
  no stable set avoids A, and
  for every seed a in A, there is a stable set S with S cap A = {a}.
```

This is the right formulation for a fixed-height transfer program. For height
4, a stable set has one of only 16 possible column patterns, and stability of a
middle column is determined by the previous, current, and next stable-set
columns. The first implementation of this idea is in
`experiments/width4_stable_sets.jl`, and it matches the simulator/minimality
predicate on all `4 x 4` configurations.

The next exact search should combine:

1. seed-column patterns;
2. reachable zero-seed stable obstructions, to certify percolation;
3. reachable one-seed stable obstructions, to certify minimality of each seed;
4. dynamic-programming state merging, so many candidate infected sets are ruled
   out together instead of simulated one at a time.

The first merged-state version counts locally viable candidates that percolate
without materializing each mask. For `4 x 10`, it gives:

| size | locally viable | locally viable and percolating |
|-----:|---------------:|--------------------------------:|
| 12 | 388,350,293 | 256,942,360 |
| 11 | 309,117,476 | 159,572,568 |
| 10 | 192,959,628 | 68,033,874 |

This was a useful reduction, but it also showed why minimality was the actual
hard part. Even after local minimality pruning and percolation filtering, size
11 still had more than 159 million percolating candidates. The next DP had to
encode the one-seed stable-set witnesses required for minimality.

A second stable-set routine now computes those witnesses in one pass for a fixed
candidate. It scans stable-set column patterns while tracking whether the stable
set has hit zero seeds or exactly one seed of `A`. At the end it reports:

1. whether there is a zero-seed stable obstruction, which means `A` does not
   percolate;
2. the set of seeds that have a one-seed stable witness, which is exactly the
   removal certificate needed for minimality.

Thus a candidate `A` is minimal percolating exactly when:

```text
no zero-seed stable obstruction exists, and
the witnessed-seed mask equals A.
```

This single-pass witness summary matches the simulator/minimality predicate on
all `4 x 4` configurations. It is still a per-candidate verifier, but its state
is the right object to merge in the next full DP.

The witness summary was also wired into a width-4 search path. It verifies
minimality by stable-set witnesses instead of by repeatedly simulating seed
deletions. This makes the certification logic closer to the intended proof
language, but candidate-by-candidate use was not enough: when applied to the
`4 x 9` extremal layer, enumeration remained the dominant cost. This motivated
merging witness-summary states across seed-column prefixes.

A witness-pruned generator was added as an intermediate step. During column
generation it carries the active one-seed witness states and immediately prunes
a branch if any already-seen seed has no possible witness left. This is a safe
minimality pruning rule: once a seed's column has passed, no future stable-set
column can newly hit that seed.

The witness-pruned generator matches the trusted exact counts on the checked
extremal layers:

| grid | size | raw minimal sets | symmetry classes |
|------|-----:|-----------------:|-----------------:|
| `4 x 4` | 5 | 360 | 90 |
| `4 x 5` | 6 | 280 | 73 |
| `4 x 8` | 8 | 7,074 | 1,778 |

It generates exactly the minimal configurations on these layers. However, it
still does not finish quickly on the `4 x 9`, size-9 layer, so the next version
must merge equivalent prefix states rather than recursively enumerating all
seed-column prefixes.

## Merged-State DP

The first successful merged-state DP is implemented in
`experiments/width4_minimality_dp.jl`. It scans seed columns from left to right
and merges prefixes with the same:

1. seed count used so far;
2. last two seed columns;
3. active stable-set states avoiding all seeds;
4. active one-seed witness obligations.

The crucial compression is that witness obligations are identified by their
future behavior, not by the absolute seed that created them. If two already-seen
seeds have the same set of possible stable-witness frontier states, the future
columns cannot distinguish them, so they can be represented once.

This DP reproduces the known exact count for `4 x 9`, size 9:

```text
raw minimal percolating sets = 1,312
```

It then certifies:

```text
4 x 10, size 12: 0
4 x 10, size 11: 0
4 x 10, size 10: 82
```

Thus the exact width-4 sequence currently known is:

| n | E(4,n) |
|--:|-------:|
| 4 | 5 |
| 5 | 6 |
| 6 | 7 |
| 7 | 8 |
| 8 | 8 |
| 9 | 9 |
| 10 | 10 |

The next computation was `4 x 11`. It found:

```text
4 x 11, size 13: 0
4 x 11, size 12: 0
4 x 11, size 11: 0
4 x 11, size 10: 145,332
```

Therefore:

```text
E(4,11) = 10.
```

This is important because it disproves the first natural conjecture
`E(4,n)=n` for all `n >= 8`. The width-4 sequence now begins:

```text
5, 6, 7, 8, 8, 9, 10, 10
```

for `n = 4,5,6,7,8,9,10,11`. The next computational target is `4 x 12`.

## Verification Script

The current computational claims can be checked with:

```text
julia --project=. experiments/verify_width4_findings.jl
```

This script verifies:

1. the stored `4 x 9` certificate files for sizes 11, 10, and 9;
2. the `4 x 10` size-10 construction;
3. the `4 x 10` locally viable and percolating DP counts;
4. the `4 x 10` merged-state certificate for sizes 12, 11, and 10;
5. the `4 x 11` merged-state certificate for sizes 13, 12, 11, and 10;
6. the witness-pruned generator against trusted extremal-layer counts for
   `4 x 4`, `4 x 5`, and `4 x 8`.
