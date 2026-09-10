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

## Minimality Proof

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

the bottom seeds occur in adjacent pairs followed by an empty bottom cell. If a
bottom seed is removed, then one of the following happens:

- at the left boundary, the first bottom cell is left uninfected;
- otherwise, the removed cell and one adjacent originally empty bottom cell
  form a pair of adjacent uninfected bottom cells.

More explicitly:

- if the removed bottom seed is the first seed of a pair, then the preceding
  column is a `00` column, except at the left boundary;
- if the removed bottom seed is the second seed of a pair, then the following
  column is a `00` column;
- if the removed bottom seed lies in the terminal block, the terminal block was
  chosen so that the same adjacent-pair obstruction still exists.

So, apart from the left-boundary case, there are adjacent columns `a` and
`a + 1` such that both `B_a` and `B_{a+1}` are initially uninfected after the
removal.

We claim that this adjacent bottom pair blocks full percolation.

Let

```text
S = {B_a, B_{a+1}} union {T_j : 1 <= j <= a+1},
```

unless `a + 1 = n`, in which case omit the initially infected terminal top cell
`T_n` and take

```text
S = {B_{n-1}, B_n} union {T_j : 1 <= j <= n-1}.
```

Every cell in `S` is initially uninfected after the bottom seed is removed.
Moreover, no cell in `S` can ever be the first cell of `S` to become infected:

- `B_a` has at most one infected neighbor outside `S`, namely `B_{a-1}`;
- `B_{a+1}` has at most one infected neighbor outside `S`, namely `B_{a+2}` or,
  at the right boundary, the terminal top cell `T_n`;
- each top cell `T_j` with `j < a+1` has all of its top-row neighbors still in
  `S`, and therefore has at most one infected neighbor outside `S`, namely its
  bottom neighbor;
- the boundary top cell `T_{a+1}` has at most one infected neighbor outside
  `S`, namely `T_{a+2}`.

Thus every cell in `S` always has at most one infected neighbor outside `S`
until some other cell in `S` is infected. Since infection requires two infected
neighbors, no cell of `S` can ever become infected. Therefore the modified set
does not percolate.

The left-boundary case is similar and even simpler. If `B_1` is removed, then
`T_1` and `B_1` are both initially uninfected. The cell `B_1` can only use
`B_2` and `T_1`, while `T_1` can only use `T_2` and `B_1`. Since `B_1` and
`T_1` depend on each other and neither is initially infected, column 1 never
fully infects.

This matches the simulator's removal checks: after deleting any bottom seed, the
final state always contains an uninfected boundary cell or an adjacent pair of
uninfected bottom cells together with the corresponding top-row blockage.

## Formal Proof Summary

Combining the previous sections:

1. The construction has exactly `floor(2(n + 2) / 3)` initially infected cells.
2. The construction percolates: the bottom row fills first, then the top row
   fills from right to left.
3. Removing the unique top seed prevents the top row from ever starting.
4. Removing any bottom seed creates a permanent obstruction, so the modified
   set does not percolate.

Therefore the construction is inclusion-minimal percolating and has size
`floor(2(n + 2) / 3)`. Morris's upper bound gives the reverse inequality, so

```text
E(2,n) = floor(2(n + 2) / 3)
```

for every `n >= 2`.

## Research Status

This is the first strong candidate for a genuine exact-family result from the
computations:

```text
E(2,n) = floor(2(n + 2) / 3) for all n >= 2.
```

It uses a known upper bound plus a new explicit construction discovered from
the exact search data.
