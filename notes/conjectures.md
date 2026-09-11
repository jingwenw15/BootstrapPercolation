# Candidate Conjectures

This file records conjectures suggested by the exact computations. They are not
proved.

## Result Candidate 1: Exact Formula For 2 x n

For every `n >= 2`,

```text
E(2,n) = floor(2(n + 2) / 3).
```

Equivalently, the Morris upper bound is sharp for every `2 x n` rectangle.

Evidence:

- verified exactly for `2 <= n <= 12`;
- every tested `2 x n` case attains the upper-bound start immediately;
- an explicit construction matching the upper bound is implemented in
  `experiments/two_row_construction.jl`.

## Disproved Candidate: Small-Rectangle Gap Is At Most One

Earlier computations suggested

```text
E(m,n) >= floor((m + 2)(n + 2) / 6) - 1.
```

Equivalently, every tested rectangle either attained Morris's upper bound or
fell exactly one below it.

This is false. Exact search gives

```text
E(4,8) = 8,
floor((4 + 2)(8 + 2) / 6) = 10.
```

So the gap from Morris's upper bound is already 2 at `4 x 8`.

## Disproved Candidate: E(4,n) = n + 1

The first `4 x n` values suggested

```text
E(4,n) = n + 1.
```

This held for `4 <= n <= 7`:

| n | E(4,n) |
|---|-------:|
| 4 | 5 |
| 5 | 6 |
| 6 | 7 |
| 7 | 8 |

But exact search found

```text
E(4,8) = 8,
```

not `9`. Thus the `n + 1` formula is false.

The `4 x 8` computation checked:

```text
size 10: 64,512,240 configurations
size 9:  28,048,800 configurations
size 8:  10,518,300 configurations
```

and found 7,074 size-8 maximizers.

## Current Open Lead: Width 4 Has Nonlinear Drops

The exact values now known for width 4 are:

| n | Morris upper start | E(4,n) | gap |
|---|-------------------:|-------:|----:|
| 4 | 6 | 5 | 1 |
| 5 | 7 | 6 | 1 |
| 6 | 8 | 7 | 1 |
| 7 | 9 | 8 | 1 |
| 8 | 10 | 8 | 2 |

This suggests the real question is not a simple `n + 1` formula. A better
research direction is to determine when width-4 rectangles lose additional
units relative to Morris's upper bound.

See `notes/novel_direction.md` for the current best target: explaining the
rigidity-to-flexibility transition between `4 x 7` and `4 x 8`.

## Most Promising Proof Target

The `2 x n` formula is already covered by Morris's exact thin-rectangle cases,
but it remains a useful check of the code. For genuinely new work, the best
target is now the width-4 sequence:

```text
E(4,4), E(4,5), E(4,6), ...
```

The next computational step is to compute or bound `E(4,9)`, but the `4 x 8`
run already required checking over 100 million candidates. Further progress
will likely need a smarter exact search or structural pruning.

For the known `2 x n` formula, a proof needs:

1. an explicit construction reaching `floor(2(n + 2) / 3)`;
2. an upper-bound argument showing that a larger inclusion-minimal percolating
   set cannot exist on two rows.

Because a `2 x n` grid has only vertical pairs and horizontal chains, it should
be possible to translate the process into a one-dimensional constraint problem
on columns.

See `notes/two_row_formula.md` for the construction and proof outline.
