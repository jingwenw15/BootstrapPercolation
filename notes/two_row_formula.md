# Exact Formula For 2 x n Rectangles

This note records a proof strategy for the `2 x n` family.

## Statement

For every `n >= 2`,

```text
E(2,n) = floor(2(n + 2) / 3).
```

Equivalently, Morris's upper bound is sharp on every `2 x n` rectangle.

## Upper Bound

Morris proves that for every rectangle `[m] x [n]`,

```text
E(m,n) <= floor((m + 2)(n + 2) / 6).
```

Setting `m = 2` gives

```text
E(2,n) <= floor(4(n + 2) / 6)
       = floor(2(n + 2) / 3).
```

Thus it remains only to construct an inclusion-minimal percolating set of this
size for every `n >= 2`.

Reference:

- Robert Morris, "Minimal percolating sets in bootstrap percolation",
  Electronic Journal of Combinatorics, 2009.
  https://arxiv.org/abs/math/0702370

## Construction

Encode a `2 x n` grid by column words:

```text
00 = empty column
01 = bottom seed
10 = top seed
11 = full column
```

Let

```text
B = 01 01 00.
```

The construction depends on `n mod 3`.

If `n = 3k`, use

```text
B^(k-1) 01 00 11.
```

If `n = 3k + 1`, use

```text
B^k 11.
```

If `n = 3k + 2`, use

```text
B^k 01 10.
```

The implementation is `two_row_extremal_construction(n)` in
`experiments/two_row_construction.jl`.

## Size Check

Each block `B = 01 01 00` contributes 3 columns and 2 seeds.

For `n = 3k`, the construction has

```text
2(k - 1) + 3 = 2k + 1 = floor(2(3k + 2) / 3).
```

For `n = 3k + 1`, the construction has

```text
2k + 2 = floor(2(3k + 3) / 3).
```

For `n = 3k + 2`, the construction has

```text
2k + 2 = floor(2(3k + 4) / 3).
```

So in all cases the construction has exactly `floor(2(n + 2) / 3)` seeds.

## Computational Verification

The construction is tested for every `2 <= n <= 30`:

- it has size `floor(2(n + 2) / 3)`;
- it percolates;
- removing any initially infected cell makes it fail to percolate.

The construction also matches the exact search values for every `2 <= n <= 12`.

The generated examples through `n = 15` are saved in
`experiments/results/two_row_constructions_2_to_15.txt`.

## Percolation Mechanism

Write the top-row cell in column `j` as `T_j` and the bottom-row cell as `B_j`.

The construction is designed so that the bottom row fills first:

- in every repeated block `01 01 00`, the empty bottom cell in the `00` column
  has infected bottom neighbors on both sides, except at the terminal end where
  the terminal block supplies the missing neighbor or vertical support;
- therefore the initially empty bottom cells become infected before the top row
  has to do any substantial work.

After the bottom row has filled, the top row is infected by a right-to-left
wave. The terminal block always supplies a top seed at the right end:

- `... 11` for `n = 0, 1 mod 3`;
- `... 10` for `n = 2 mod 3`.

Once `T_{j+1}` is infected and `B_j` is infected, the cell `T_j` has two
infected neighbors and becomes infected. Thus the top infection propagates one
column at a time from right to left.

The infection-time matrices computed by the simulator have exactly this shape:
the bottom row is infected at time `0` or `1`, and the top row then fills from
right to left.

## Minimality Mechanism

There are two kinds of initially infected cells.

### Removing The Top Seed

The construction has exactly one top-row seed. If that seed is removed, then the
top row has no initially infected cells. A top-row cell can only become infected
using its vertical bottom neighbor together with an infected horizontal top
neighbor. Since there is no first infected top-row cell, the top row never
starts. Hence the set does not percolate.

### Removing A Bottom Seed

Deleting a bottom seed creates a stable obstruction in the bottom row.

In the repeated block pattern

```text
01 01 00
```

the bottom seeds occur in adjacent pairs followed by an empty bottom cell. If
one of the two bottom seeds in such a pair is removed, then either:

- the removed cell and the following empty bottom cell form two adjacent
  uninfected bottom cells, or
- the preceding empty bottom cell and the removed cell form two adjacent
  uninfected bottom cells.

At the left boundary, removing the first bottom seed leaves the first column
uninfected forever. At the right boundary, the terminal block gives the analogous
one- or two-column obstruction.

For an interior adjacent uninfected pair `B_j, B_{j+1}`, infection cannot pass
through the pair:

- `B_j` needs either `B_{j-1}` and `B_{j+1}`, or `B_{j+1}` and `T_j`, or
  `B_{j-1}` and `T_j`;
- `B_{j+1}` has the analogous dependency;
- the top cells `T_j` and `T_{j+1}` also need vertical support from the
  corresponding bottom cells in order for the right-to-left top wave to cross.

Thus the pair creates a mutual dependency: the bottom cells need the top cells
or each other, while the top cells need the bottom cells. The infection may fill
on the right side of the obstruction, but it cannot cross the obstruction and
infect every cell.

This matches the simulator's removal checks: after deleting any bottom seed, the
final state always contains an uninfected boundary cell or an adjacent pair of
uninfected bottom cells together with the corresponding top-row blockage.

## Formal Proof Still To Write

The remaining polishing work is to convert the mechanisms above into a concise
induction over the repeated block `01 01 00`.

The proof should have three lemmas:

1. bottom-row filling lemma;
2. top-row right-to-left propagation lemma;
3. bottom-seed removal barrier lemma.

Together with Morris's upper bound, these lemmas prove the formula.

## Research Status

This is the first strong candidate for a genuine exact-family result from the
computations:

```text
E(2,n) = floor(2(n + 2) / 3) for all n >= 2.
```

It uses a known upper bound plus a new explicit construction discovered from
the exact search data.
