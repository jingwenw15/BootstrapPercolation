# Fixed-Width Common Growth: Stage 3

## Result

For every fixed positive height `h`, there are effectively computable integers
`p_h > 0`, `q_h >= 0`, and `N_h` such that

```text
E(h, n+p_h) = E(h,n) + q_h  for all n >= N_h.
```

Consequently a single limiting density exists and is rational:

```text
rho_h = lim_(n -> infinity) E(h,n)/n = q_h/p_h.
```

The finite-state and semilinear arguments from Stages 1 and 2 supply eventual
affine formulas by residue. Monotonicity, which is already Morris's Lemma 7,
forces their gains to agree. The remaining step from our previous notes is
therefore resolved by an existing result, not a new extension lemma.

## The known monotonicity theorem

Morris (2009), Lemma 7, proves `E(k,l) <= E(m,n)` whenever `k <= m` and
`l <= n`. In particular,

```text
E(h,n+1) >= E(h,n).
```

The lemma appears on page 7 of the published paper:

<https://www.combinatorics.org/ojs/index.php/eljc/article/download/v16i1r2/pdf#page=7>

The following closure argument expands the boundary step used in its
construction, in the row/column convention of this project.

## Why the added column cannot help the old rectangle

Let `T` be any initial infected subset of an `h x n` rectangle, with
`a = (r,n)` in `T`. Let `H` be its bootstrap closure inside that rectangle.
Append a new column with just `b = (r,n+1)` initially infected.

Let `I` be the maximal interval of row indices containing `r` such that
`(s,n)` belongs to `H` for every `s in I`. Define

```text
H' = H union {(s,n+1): s in I}.
```

This is closed under bootstrap infection on the enlarged grid:

1. An old cell outside `H` has at most one neighbor in `H`, since `H` is
   closed. It cannot gain a neighbor from the new part of `H'`: if its row
   were in `I`, that old boundary cell would already belong to `H`.
2. A new-column cell outside `I` and adjacent vertically to `I` has its old
   neighbor outside `H`, by maximality of `I`. It has at most one vertical
   neighbor in the interval `I`, so it has at most one neighbor in `H'`.
3. Every other new-column cell outside `I` has no vertical neighbor in `I`
   and at most its single old neighbor in `H'`.

It follows that the closure of `T union {b}` is contained in `H'`. In
particular, adding this single seed in the new column does not increase the
infected closure within the old rectangle.

This argument concerns closure only; it neither assumes nor changes the
synchronous timing used by the simulator.

## Extension construction and minimality

Take an inclusion-minimal percolating set `A` on `h x n`. Its last column
contains a seed: an entirely empty boundary column could never infect its
first cell, because each cell has at most one neighbor outside that column.
Choose any boundary seed `a = (r,n)` and its new neighbor `b = (r,n+1)`.

Form the two sets

```text
B = A union {b},
C = (A without {a}) union {b}.
```

The set `B` percolates. First the old rectangle fills using `A`; then the
new column fills outward from `b`, supported by the infected old boundary.

If `C` percolates, it is minimal. Removing `b` leaves an empty new column,
which cannot fill. For any other seed `v` of `C`, minimality of `A` says the
old closure of `A without {v}` is a proper subset of the old rectangle. This
set still contains `a`. The preceding closure argument shows that even
`(A without {v}) union {b}` cannot infect the whole old rectangle, and
`C without {v}` is a subset of that set. Therefore it cannot percolate.

If `C` does not percolate, `B` is minimal. Removing `a` gives `C`, removing
`b` leaves an empty new column, and deleting any other seed is ruled out by
the same closure argument.

Thus either `C` or `B` is minimal percolating, with respectively `|A|` or
`|A|+1` seeds. This proves monotonicity and implements Morris's construction.
It does not bound the increase in the extremal function by one: larger
minimal sets on the enlarged rectangle might use different arrangements.

## All residue gains must agree

By Stage 2, choose a common period `p` and residue formulas

```text
E(h,pk+r) = q_r*k + b_r,    0 <= r < p,
```

valid for all sufficiently large `k`. Monotonicity gives, for `r < p-1`,

```text
q_r*k + b_r <= q_(r+1)*k + b_(r+1).
```

Letting `k` increase forces `q_r <= q_(r+1)`. At the wraparound residue it
also gives

```text
q_(p-1)*k + b_(p-1) <= q_0*(k+1) + b_0,
```

so `q_(p-1) <= q_0`. These inequalities form a cycle; hence every gain equals
one integer `q`. Taking `K >= 0` at least every residue threshold and
`N_h = max(1,p*K)` proves the common recurrence in the statement, with
`p_h = p` and `q_h = q`.

Dividing the residue formula by `pk+r` proves that all subsequences have
limit `q/p`, so the overall limit exists. More precisely,

```text
E(h,n) = (q/p)*n + beta_(n mod p)
```

eventually, where `beta_r = b_r - q*r/p` is rational and periodic. The
eventual first differences are nonnegative and periodic as well. Their sum
over one period is `q`.

## Verification and limits

`experiments/minimal_extension.jl` validates the input set and applies the
two-case extension, selecting `C` when it percolates and `B` otherwise. The
tests check every minimal set on every rectangle with height and length at
most four and at most twelve cells, using every possible infected seed on
the right boundary. Each result is checked with the direct simulator and
every single-seed removal, including input preservation.

The suite also checks the boundary-closure property for every initial set on
rectangles of height at most four, length at most three, and at most nine
cells. Including repeated extensions and invalid inputs, the new extension
suite has 3,442 passing checks.

The generic theorem is a written mathematical argument. Tests support the
construction's implementation; they do not prove the theorem for all heights.
This stage supplies no new values for width five or above and does not audit
every transition of the separate width-four graph certificate.

## Attribution and correction

Reference: Robert Morris, "Minimal Percolating Sets in Bootstrap Percolation,"
Electronic Journal of Combinatorics 16 (2009), #R2, Lemma 7:

<https://doi.org/10.37236/91>

Our earlier notes incorrectly presented dimension monotonicity as unresolved.
That literature omission is corrected here. The extension and monotonicity
belong to Morris. The full fixed-height recurrence follows by combining that
known result with our written finite-state reduction and the classical
semilinear argument. No source checked so far states the complete recurrence
for every height, but novelty is still unconfirmed: this consequence may be
implicit in existing bounded-width automata methods.
