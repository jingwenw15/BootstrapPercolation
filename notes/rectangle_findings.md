# Rectangular Exact Values

This note records the first exact rectangular table computed by the
size-ordered search in `experiments/rectangle_table.jl`.

The computation covers rectangles `[m] x [n]` with `2 <= m <= n <= 5`.
For each rectangle, the search starts at Morris's upper bound

```text
floor((m + 2)(n + 2) / 6)
```

and checks candidate seed sets by size in descending order. A value is certified
once every larger size has been ruled out and at least one inclusion-minimal
percolating set is found.

## Exact Table

| m | n | Morris upper start | E(m,n) | raw maximizers | checked candidates |
|---|---|-------------------:|-------:|---------------:|-------------------:|
| 2 | 2 | 2 | 2 | 2   | 6         |
| 2 | 3 | 3 | 3 | 10  | 20        |
| 2 | 4 | 4 | 4 | 6   | 70        |
| 2 | 5 | 4 | 4 | 48  | 210       |
| 3 | 3 | 4 | 4 | 9   | 126       |
| 3 | 4 | 5 | 4 | 132 | 1,287     |
| 3 | 5 | 5 | 5 | 228 | 3,003     |
| 4 | 4 | 6 | 5 | 360 | 12,376    |
| 4 | 5 | 7 | 6 | 280 | 116,280   |
| 5 | 5 | 8 | 7 | 88  | 1,562,275 |

The machine-readable report is saved as
`experiments/results/rectangle_table_2_to_5.csv`.

## Observations

The exact values for this range are:

```text
E(2,2) = 2
E(2,3) = 3
E(2,4) = 4
E(2,5) = 4
E(3,3) = 4
E(3,4) = 4
E(3,5) = 5
E(4,4) = 5
E(4,5) = 6
E(5,5) = 7
```

Some small rectangles attain Morris's upper-bound start exactly:

```text
(2,2), (2,3), (2,4), (2,5), (3,3), (3,5)
```

Others fall one below it:

```text
(3,4), (4,4), (4,5), (5,5)
```

The square values through `n = 5` are therefore:

```text
E(2) = 2, E(3) = 4, E(4) = 5, E(5) = 7.
```

## Why This Is Potentially Useful

The rectangular table is more informative than the square sequence alone.
For example, `E(3,4) = 4` but `E(3,5) = 5`; similarly, `E(4,4) = 5` and
`E(4,5) = 6`. These jumps may indicate that extremal configurations are
sensitive to aspect ratio and boundary length, not only to area.

This table also gives test cases for any proposed recurrence or construction.
Any conjectural formula for small rectangles must explain both the upper-bound
attaining cases and the one-below-upper-bound cases.

## Next Questions

1. Compute symmetry-class representatives for rectangular maximizers using the
   rectangle automorphism group.
2. Extract row and column seed profiles from all maximizers.
3. Compare extremal examples that attain the upper bound with those that fall
   one below it.
4. Attempt selected larger rectangles, especially `3 x 6`, `4 x 6`, and
   `5 x 6`, before attempting the full `6 x 6` square.

## Selected Width-6 Rectangles

The following extra cases were computed after the `2 <= m <= n <= 5` table.

| m | n | Morris upper start | E(m,n) | raw maximizers | checked candidates |
|---|---|-------------------:|-------:|---------------:|-------------------:|
| 2 | 6 | 5 | 5 | 56 | 792 |
| 3 | 6 | 6 | 6 | 98 | 18,564 |
| 4 | 6 | 8 | 7 | 40 | 1,081,575 |

The reports are saved as:

- `experiments/results/exact_search_2x6.txt`
- `experiments/results/exact_search_3x6.txt`
- `experiments/results/exact_search_4x6.txt`

These cases strengthen the emerging pattern that small rectangles often either
attain Morris's upper-bound start exactly or fall one below it. In the computed
range so far, the one-below cases are:

```text
(3,4), (4,4), (4,5), (5,5), (4,6)
```

The upper-bound-attaining cases are:

```text
(2,2), (2,3), (2,4), (2,5), (2,6), (3,3), (3,5), (3,6)
```

This suggests a concrete next conjecture-search problem: characterize small
rectangles for which `E(m,n) = floor((m + 2)(n + 2) / 6)` versus those for which
the exact value is one lower.
