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
