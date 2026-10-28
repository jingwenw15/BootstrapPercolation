# The First Unbounded Crowding Height Is Seven

Proof draft, 2026-10-25. External proof review and novelty confirmation remain
outstanding. The height-seven construction is existing work, not ours.

## Results and Scope

Let `M(h)` be the supremum of the crowded-column count over all inclusion-
minimal percolating sets on all finite `h x n` grids. A crowded column has
at least two initial seeds.

**Theorem.** `M(6)=16`. Every six-row minimal percolating set has at most
sixteen crowded columns, uniformly in width. A `6 x 75` example attains
sixteen, with 54 seeds.

**Threshold consequence.** The smallest height with unbounded crowding is
seven. The upper endpoint is supplied by Gottschau's existing height-seven
construction. Combining it with the bounded-height proofs gives

```text
h       1  2  3  4  5   6    7
M(h)    0  1  2  4  8  16  infinity.
```

This is not a formula for the largest total seed count `E(6,n)` or `E(7,n)`.
In particular, we do not assert `E(6,75)=54`.

## Two Reusable Lemmas

We use the direct height-four and height-five arguments, including the
classical rectangles process, seed nonrecoverability, the full-height-strip
lemma, and the one-sided cap on seeds in the next two rows.

### A Two-Row Anchor Against a Larger Strip

The height-five bridge argument only used the fact that its other strip was
filled, not that this strip had height two. Consequently, if a two-row
internally spanned rectangle and another internally spanned rectangle are
separated vertically by one row and overlap in column projection, the first
rectangle has at most two seeds in the other's column interval in a globally
minimal configuration.

Choose the first rectangle's two-seed, width-at-most-two anchor. If it overlaps
the other interval, the anchor and other rectangle fill their full-height
bounding rectangle, recovering every extra first-rectangle seed in that
interval. If the anchor is disjoint, extend the filled two-row rectangle
to the nearest first-rectangle seed in the other interval. Combining with
the other rectangle then recovers any farther seed in that interval. This
is the same proof as the height-five bridge lemma, including the case of
two seeds in one column. Disjoint column projections give a zero count.

The two-seed anchor fact is already used by Morris in Theorem 9(b); it is
not a new ingredient.

### Projection Recovery for Two Adjacent Three-Row Strips

Let `S,T` occupy rows `1..3` and `4..6`, respectively, and be internally
spanned by disjoint owning seed sets `B,C` within a globally minimal set.
Let `J` be `T`'s column interval. Suppose a subset `D` of `B` internally
spans a full-three-row subrectangle `U` of `S`, with column interval `I`.

If `I` intersects `J`, then `U` and filled `T` merge into a height-six
rectangle containing all of `J`. Minimality implies

```text
every seed of B with column in J belongs to D.
```

If `I` is disjoint from `J`, there is at most one seed of `B` in `J`.
To see this, extend filled `U` toward `J` using only seeds of `B` outside
`J` and one nearest seed inside `J`. This extension is possible because
`B` spans `S`, so there is no double empty column gap. It fills all three
rows as far as that seed. This rectangle meets `T`, and their union fills
a six-row rectangle containing all of `J`, recovering every other seed of
`B` there. Global minimality forbids this. If two seeds share the nearest
column, using either one also recovers the other.

## The Three-Row Overlap Lemma

**Lemma.** In the situation above, at most four seeds of `B` have columns
in `J`. In particular, there are at most four mixed columns. Reflection
gives the same statement for the other strip.

**Proof.** Run a rectangles process on `B` inside `S`, and take its first
three-row rectangle, whose two children have height at most two. We find a
full-three-row subrectangle `U` with an owning subset `D` for which at most
four seeds of `D` have columns in `J`. Projection recovery then proves the
claim whether `U` meets `J` or not.

There are three cases, with rows measured relative to `S`:

1. **A child occupies rows `1..2`, away from `T`.** Its owning seeds in `J`
   number at most two by the two-row-anchor lemma: rows `1..2` and `4..6`
   have one intervening row. The other child's rows are in `2..3`. There
   is at most one seed of the entire minimal set in these two rows within
   `J`, by the one-sided seed cap applied above filled `T`. Take `U` to
   be the first three-row rectangle itself and `D` to be its two owning
   seed sets. At most `2+1=3` of these seeds have columns in `J`.
2. **There is a height-two child only in rows `2..3`, near `T`.** The other
   child is a one-row interval in row one. Some initial seed of that line
   lies at distance at most two from the height-two rectangle. If their
   column intervals are disjoint, take the nearest endpoint seed. If
   they overlap, every site of an internally spanned one-row interval
   is within one column of an initial seed. That seed together with the
   filled height-two child spans a three-row rectangle `U`. Take `D` to
   be that child's seeds plus this one seed. At most one child seed lies
   in `J`, by the one-sided cap, so at most two seeds of `D` lie there.
3. **Both children have height one.** Their rows are one and three, and
   their column intervals overlap. Choose a column in the intersection.
   In each one-row interval its site is initially infected or has two
   initially infected horizontal neighbors; otherwise that line could
   not span its interval. At most two initial seeds per row infect the
   chosen column. The resulting two one-row rectangles are distance two
   apart and fill their three-row bounding rectangle `U`. Thus `D` has
   at most four seeds in total.

These cases are exhaustive. Projection recovery gives the uniform bound
four, independent of the widths of the rectangles. This is a geometric
argument, not a finite search or assumed automaton stabilization.

## Proof of the Sixteen-Column Bound

Take the first six-row rectangle in a rectangles process on a minimal
percolating set `A`. Its children have heights at most five, are internally
spanned by minimal owning seed sets, and account for exactly the initial
seeds in their bounding rectangle. All crowded columns of `A` lie in that
rectangle. As before, a mixed column contains a seed from each child.

| Case | Upper bound on crowded columns |
|---|---:|
| No mixed column | `8+8=16` |
| Mixed column and a height-five child | `8+1=9` |
| Mixed column and maximum child height four | `4+4+1=9` |
| Two adjacent height-three children | `2+2+4=8` |
| Height-two and height-three children with one intervening row | `1+2+2=5` |

For the second case, one extra seed fills the missing row and creates a
full-height strip. For the third case, the height-four child must occupy
the top or bottom four rows: an interior four-row child and any other
child of height at most four cannot reach both outer rows. Its two outside
rows are on the same side, so the one-sided seed cap allows at most one
mixed column. The fourth case uses the three-row overlap lemma. The fifth
uses the generalized two-row anchor lemma. With maximum child height three,
these last two row patterns are the only ways to span six rows at distance
at most two. Smaller children cannot merge to span six rows.

Thus all cases give at most sixteen crowded columns, for every width.

## Sharpness at Width 75

Let `V` be the five-row sharpness word from `height5_crowding.md`, of width
35 with eight crowded columns. Append `[0,1]`, put this 37-column word in
the top five rows, leave one empty column, and place its 180-degree rotation
in the bottom five rows. Each arm fills its five-row rectangle, and the
two arms merge across the empty middle column. The resulting `6 x 75`
configuration has 54 seeds and sixteen crowded columns.

All 54 deletions have explicit stable-fort witnesses in
`experiments/results/height6_crowding.toml`. Each fort contains its deleted
seed, avoids the other seeds, and gives every fort cell at most one grid
neighbor outside. The original simulator separately verifies percolation
and every deletion. Together these local certificates establish sharpness;
the upper bound does not depend on those tests.

## The Known Height-Seven Family

The previous range `{6,7,8}` used Morris's height-eight family and was valid
but not the strongest available range. We have now retrieved and visually
checked Gottschau's original 2020 dissertation: Lemmas 50--51 and Figure
3.5, printed pages 66--68, give a height-seven construction. This is prior
work and must not be presented as a new construction.

Here is an explicit specialization, useful for reproduction. For `k>=1`,
let `N=3k+2` and

```text
P = {3i+2, 3i+4 : 0 <= i < k}.
```

Seed both row one and row seven at every column of `P`, and add

```text
(2,2), (6,N-1), (3,N), (5,1).
```

This has `4k+4` seeds and `2k` crowded columns. Each outer two-row arm fills
columns `2..N-1`; the outboard seeds at `(3,N)` and `(5,1)` extend them to
three-row arms in rows `1..3`, columns `2..N`, and rows `5..7`, columns
`1..N-1`. These merge across row four and fill the grid.

For completeness, minimality can be checked uniformly, without extrapolating
from sampled values of `k`. The configuration is invariant under a
180-degree rotation, so consider only the top arm and its connector.

- Deleting `(3,N)` leaves the entire last column empty, preventing percolation.
- Deleting `(2,2)` leaves three closed, pairwise-distance-at-least-three
  rectangles: row one on columns `2..N-1`; the singleton `(3,N)`; and
  rows `5..7` on columns `1..N-1`. They contain all remaining seeds and
  do not cover the grid.
- Deleting a row-one seed splits the remaining row-one seeds into at most
  two intervals after their one-row closure. If the first seed remains,
  its left interval and `(2,2)` fill a two-row prefix ending at most at
  column `N-3`; otherwise `(2,2)` is a singleton. Any right interval remains
  in row one and ends at `N-1`. These pieces, `(3,N)`, and the unchanged
  bottom three-row rectangle are pairwise at distance at least three.
  Hence their union is a proper closed set containing the remaining seeds.
  The gap assertion follows directly from the `110`-type seed pattern:
  deleting any seed creates a double empty gap or deletes an endpoint.

By rotation this covers every seed. Thus the family is minimal for every
`k`, and its `2k` crowded columns prove unboundedness at height seven.
This proves that the smallest unbounded height is exactly seven when
combined with the bounded-height results through six.

## Reproduction and Priority

```text
julia --project=. experiments/height6_crowding.jl
julia --project=. test/runtests.jl
```

The tests validate three-row nuclei against direct closure, test predicted
redundant seeds on overlapping pairs of three-row minimal sets in both
orientations, and include genuinely minimal overlapping examples. They
exhaust six-row grids through width three, verify the 54 local sharpness
forts, and reproduce the known seven-row family for `k=1,...,12`. Finite
tests corroborate the proof; they are not the all-width justification.

Source: Gottschau, *Cuts, Paths, and Processes in Graphs* (2020),
[original dissertation](https://mediatum.ub.tum.de/doc/1548760/4ipl7t3ed3kdnhqurb99vwm21.Dissertation_upload.pdf),
Lemma 51 and Figure 3.5. The PDF was downloaded successfully and inspected
visually, superseding the earlier HTTP-429-limited review of those passages.
The two-row anchor belongs to Morris, and the rectangles process is classical.
The sharp height-six bound and the bounded/unbounded threshold statement
still require external proof and priority review; no novelty claim or Lean
formalization is asserted.
