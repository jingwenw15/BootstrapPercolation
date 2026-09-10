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

## Remaining Proof Obligation

The only part not written as a formal mathematical proof here is the inductive
verification that the construction is inclusion-minimal percolating for every
`n`.

The intended proof should use the repeated block structure:

```text
01 01 00
```

together with the terminal block determined by `n mod 3`. The infection spreads
through the repeated blocks once the terminal columns activate the nearest empty
column. Minimality should follow because each seed is needed either to complete
its own column or to supply one of the two neighbors that activates a later
empty column.

## Research Status

This is the first strong candidate for a genuine exact-family result from the
computations:

```text
E(2,n) = floor(2(n + 2) / 3) for all n >= 2.
```

It uses a known upper bound plus a new explicit construction discovered from
the exact search data.
