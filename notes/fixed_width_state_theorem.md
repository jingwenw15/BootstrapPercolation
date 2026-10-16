# Fixed-Width State Theorem: Stage 1

## Objective

For a fixed height `h`, encode inclusion-minimal percolating sets on the
`h x n` grid by a finite weighted automaton whose input letters are seed
columns. This note specifies the semantic state and proves the correspondence
between accepted words and minimal percolating sets.

Stage 2 is now written in `fixed_width_eventual_growth.md`. It proves eventual
residue-wise affine behavior using a semilinear description of accepted
length/weight pairs and an elementary minimum-loss argument.

## Stable-set characterization

Call a nonempty vertex set `S` stable if every vertex of `S` has at most one
neighbor outside `S`.

**Lemma 1.** A seed set `A` fails to percolate if and only if there is a stable
set `S` disjoint from `A`.

**Proof.** If such an `S` exists, every vertex of `S` has at most one neighbor
outside `S`. Even if every vertex outside `S` becomes infected, no vertex of
`S` ever has two infected neighbors, so `A` cannot percolate. Conversely, run
the process to closure and let `S` be the nonempty set of vertices that remain
healthy. Every vertex of `S` has at most one neighbor outside `S`; otherwise it
would have become infected. Thus `S` is stable and disjoint from `A`. QED.

**Lemma 2.** A seed set `A` is inclusion-minimal percolating if and only if:

1. no nonempty stable set is disjoint from `A`; and
2. for every `a in A`, there is a stable set `S_a` with
   `S_a intersect A = {a}`.

**Proof.** The first condition is Lemma 1. Applying Lemma 1 to `A \ {a}` says
that deleting `a` prevents percolation exactly when a stable set avoids every
seed except possibly `a`. The first condition rules out avoiding `a` as well,
so the intersection must be exactly `{a}`. QED.

## Column frontier

Represent a subset of one column by an `h`-bit pattern. A partial stable-set
frontier after reading column `j` is

```text
(L, C, e),
```

where `L` and `C` are the stable-set patterns in columns `j-1` and `j`, and
`e` records whether any nonempty stable column has appeared. The fictitious
columns to the left of the grid are empty.

When a new pattern `R` is chosen for column `j+1`, all neighbors of the cells
in `C` are known. The transition is legal exactly when every cell of `C` has
at most one grid neighbor outside `L union C union R`. Boundary positions are
handled by omitting nonexistent neighbors. The new frontier is
`(C, R, e or R != empty)`.

There are only

```text
2^(2h + 1)
```

possible raw stable frontiers for fixed `h`.

## Semantic automaton state

After reading seed columns `A_1,...,A_j`, the automaton state is

```text
(A_(j-1), A_j, Z, O).
```

Its components have the following exact meanings.

* `A_(j-1), A_j` are the last two seed columns. They are used to reject an
  initially infected vertex having two initially infected neighbors.
* `Z` is the set of all stable frontiers realizable by a partial stable set
  that avoids every seed in the prefix.
* Each member `W` of `O` is an unresolved seed-witness obligation. For some
  processed seed `a`, `W` is exactly the set of frontiers realizable by partial
  stable sets whose intersection with the processed seeds is `{a}`.

Obligations with equal frontier sets are identical predicates on every future
suffix and may be merged. Thus `O` is a set, rather than a list indexed by all
past seed positions. Since `Z` is a subset of a finite frontier set and `O` is
a set of such subsets, the number of semantic states is finite for every fixed
height, independently of `n`.

## Transition invariant

Suppose the invariant above holds before seed column `B` is read.

1. Advance every frontier in `Z` using stable column patterns disjoint from
   `B`. This gives the new `Z` exactly.
2. Advance every existing obligation in the same way. Its distinguished old
   seed remains the unique seed hit by its partial stable sets.
3. For each seed `b in B`, start a new obligation by advancing the old `Z`
   through stable patterns whose intersection with `B` is exactly `{b}`.
4. If an obligation already has a legal completion using empty stable columns
   forever, its witness is complete and the obligation is removed.
5. If an unresolved obligation has no frontier, reject the prefix: no suffix
   can supply a witness for its seed.
6. If `Z` has a nonempty legal completion using empty stable columns forever,
   reject the prefix: it already contains a stable obstruction disjoint from
   every seed, and no future seed can intersect that completed obstruction.

Items 1-3 preserve the invariant by induction. Items 4-6 are safe because a
completed stable set has no vertices in future columns.

During every ordinary transition, the next grid column is treated as existing;
the missing right neighbor is applied only by the final acceptance operation.
The first and second input columns use the appropriate left-boundary rules;
from the third input column onward the transition relation is stationary.
Include a finite phase (prefix length zero, one, or at least two) to make this
an ordinary finite automaton. Equivalently, the right boundary is a fixed
zero-weight end marker.

The local seed-degree rejection is also sound. If a seed `a` initially has two
infected neighbors, then after deleting `a` it is reinfected in the first
round. Whenever `A` percolates, `A \ {a}` therefore percolates as well, so `A`
cannot be inclusion-minimal.

## Acceptance theorem

At the right boundary, use an empty fictitious next column and omit nonexistent
right neighbors. Accept exactly when:

1. the final seed column passes the local seed-degree condition;
2. `Z` has no nonempty stable completion; and
3. every witness obligation has completed.

**Theorem 3.** A word of `n` seed-column patterns is accepted if and only if its
seed set is inclusion-minimal percolating on the `h x n` grid.

**Proof.** By the transition invariant, condition 2 says exactly that no
nonempty stable set avoids all seeds. By Lemma 1, this is equivalent to
percolation. Condition 3 says exactly that every seed has a stable set meeting
the seed set only at that seed. By Lemma 2, these conditions are equivalent to
inclusion-minimal percolation. The local rejection removes only configurations
that cannot be minimal, as proved above. QED.

Giving a transition the weight `|B|` makes the weight of an accepted word equal
to the number of seeds. Therefore `E(h,n)` is the maximum weight of an accepted
length-`n` path in a finite weighted automaton.

## Independent executable model

`experiments/fixed_width_state_model.jl` implements this specification using
ordinary Julia sets and tuples. It does not use the packed 512-bit frontier
representation or transition functions from the width-four certificate.

The tests compare this model with direct bootstrap closure:

* word-by-word for every configuration on several grids through `3 x 4`;
* aggregate minimal-set counts, maximum sizes, and maximizing counts through
  `3 x 4` in the routine suite.

The stronger independent `4 x 4` audit can be reproduced with:

```text
julia experiments/fixed_width_state_model.jl 4 4 false
```

It gives 490 minimal percolating sets, maximum size 5, and 360 maximizing
configurations, exactly matching direct closure. Passing `false` folds the
fixed right-boundary end marker into the final seed transition; this recognizes
the same finite words while avoiding stationary states that cannot survive the
end marker. The literal model takes about 90 seconds for this case, so it is
not part of every routine test run.

This is executable evidence for the specification, not a substitute for the
proof above.

## Stage 2 conclusion

The proof in `fixed_width_eventual_growth.md` establishes the weighted-graph
lemma in the following form:

```text
For any finite integer-weighted automaton, the maximum weight f(n) of an
accepted walk of length n is eventually affine on each residue class that
has infinitely many accepted lengths, and is eventually absent on the others.
```

For the bootstrap automaton an accepted word exists at every positive length.
Thus there is a period `p` such that for every residue `r` there are integers
`q_r`, `b_r`, and `K_r` with

```text
f(pk + r) = q_r k + b_r  for all k >= K_r.
```

One cannot assert a common gain `q_r` from finiteness alone. For example, a
finite automaton may route even lengths through a positive-mean component and
odd lengths through a zero-mean component. The slopes then differ by residue.

Applied to Theorem 3, the unconditional fixed-height conclusion is that
`E(h,n)` is eventually quasi-linear, with a rational asymptotic slope on each
residue class. A single recurrence

```text
E(h, n + p_h) = E(h, n) + q_h
```

and the existence of one overall limit `E(h,n)/n` follow by also using the
known dimension-monotonicity theorem, Morris (2009), Lemma 7. Stage 3 in
`fixed_width_common_growth.md` gives the complete deduction. Thus the common
gain is now established for every fixed height, although its value need not
be known explicitly. The width-four certificate determines `p_4 = 3` and
`q_4 = 2`.
