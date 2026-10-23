# Direct Geometric Proof of the Four-Crowded-Column Bound

Draft dated 2026-10-22. This proves the upper bound without enumeration,
frontier states, max-plus recurrences, or the formula for `E(4,n)`. It is a
mathematical proof draft, not a Lean formalization or external review.

## Theorem

In two-neighbor bootstrap percolation with open boundaries, every
inclusion-minimal percolating set on a `4 x n` grid has at most four columns
containing two or more initial seeds. Four is attained.
Equivalently, a percolating configuration with five crowded columns has a
seed whose deletion preserves percolation.

More generally, the upper bounds on crowded columns at heights one, two,
three, and four are respectively `0,1,2,4`.

Coordinates are `(row,column)`. A rectangle is a product of consecutive row
and column intervals. It is internally spanned by `B` when `B` lies inside
the rectangle and infects it using only infections within that rectangle.
All arguments concern eventual closure, so legal sequential filling arguments
are valid for the synchronous process as well: monotonicity ensures every
site in such a filling eventually becomes infected.

## 1. No Seed Can Be Recovered From Other Seeds

If `A` is minimal percolating and `B` is a subset of `A`, then

```text
[B] intersects A exactly in B.
```

Indeed, if a seed `x` outside `B` were infected by `B`, then `A` without `x`
would recover `x` and hence percolate, contradicting minimality.

Consequently, if a rectangle `S` is internally spanned by `B` contained in
`A`, then `B = A intersect S`. Also, `B` is itself minimal percolating on
`S`; otherwise a removable seed in `B` would also be removable from `A`.
If two internally spanned rectangles have disjoint owning seed sets, no
initial seed can lie in their geometric intersection.

## 2. A Full-Height Strip Removes All Outside Crowding

**Lemma.** If `A` is minimal percolating and internally spans a full-height
rectangle with column interval `J`, every crowded column of `A` belongs to `J`.

**Proof.** Any percolating configuration has a seed in each outermost column
and cannot have two consecutive completely empty columns. An empty outermost
column, or a pair of empty consecutive columns, remains empty forever.

Keep the seeds spanning the strip and just one arbitrary seed in each
occupied column outside `J`. This subset still percolates. From a filled
full-height strip, the next occupied column is one or two columns away. In
the first case its seed spreads vertically using the filled neighboring
column. In the second case, the site in the intervening column at the seed's
row first gains two horizontal infected neighbors; vertical spreading then
fills the intervening column and the seed's column. Repeat in both directions.

The endpoint and empty-column conditions guarantee this reaches both ends.
Minimality therefore forbids a second seed in any outside column. This
argument is about all minimal sets, not maximum-cardinality sets.

## 3. At Most One Nearby Outside Seed on Either Side of a Rectangle

**Lemma.** Suppose `S=I x J` is internally spanned in a minimal set `A`.
Among seeds whose columns belong to `J`, at most one can lie in the two rows
immediately above `I`. The same holds for the two rows immediately below.
Only rows actually present in the grid are counted.

**Proof.** Once `S` fills, a seed in the adjacent outside row fills that row
across `J`, because an infected neighbor in `S` and horizontal propagation
suffice. A seed two rows away first infects the intervening site using its
two vertical neighbors. The intervening row then fills across `J`, followed
by the seed's row.

If there were at least two such outside seeds on the same side, choose one
farthest from `I`. That seed together with the seeds of `S` fills the whole
rectangle between `I` and its row, recovering every other seed in the stated
two-row band. This contradicts Section 1.

## 4. The First Full-Height Rectangle Has Two Smaller Children

We use the classical rectangles process: begin with one single-site rectangle
per seed. Whenever two current rectangles are at minimum grid `L1` distance
at most two, replace them by their smallest bounding rectangle, assigning it
the union of their disjoint seed sets.

Two filled rectangles at this distance fill their bounding rectangle. When
their projections overlap, infection propagates along the overlapping strips
and then into the remaining corners. If both projections are disjoint, the
distance condition forces diagonally adjacent nearest corners; these fill
the intervening `2 x 2` bridge, after which the same strip propagation applies.
Thus every recorded rectangle is internally spanned by its owning seeds.

For completeness, at termination the union of the rectangles is closed:
an outside site has at most one neighbor in any single rectangle, and two
neighbors in distinct rectangles would put those rectangles at distance at
most two. Since the union contains `A`, a percolating `A` forces this union
to be the entire grid. Separation then forces a single final rectangle.

For height `h>=2`, consider the **first** recorded rectangle `R` of height
`h`. It is created from two rectangles `S,T` of heights strictly less than
`h`, with disjoint seed sets `B,C`. By Section 1,

```text
A intersect R = B union C,
B = A intersect S, C = A intersect T,
and B,C are minimal percolating in S,T respectively.
```

By Section 2, all crowded columns of `A` lie inside `R`. Call a column
mixed if it contains at least one seed of `B` and at least one seed of `C`.
If there are no mixed columns, the total crowded-column count is at most the
sum of the crowded-column counts of `B` and `C`.

The rectangles process is classical, not a new algorithm or lemma here. See
[Aizenman and Lebowitz (1988), Section 2 and Lemma 1](https://sites.math.rutgers.edu/~lebowitz/PUBLIST/jllpub_299b.pdf).
The attribution is to that ingredient, not to the crowded-column bounds.

## 5. Heights Two and Three

Height one has no crowded columns. At height two, any crowded column is
already a full-height filled strip, so Section 2 permits no other crowded
column. Thus the height-two bound is one.

At height three, apply Section 4. With no mixed column, each child has height
at most two and therefore at most one crowded column, giving at most two.

If there is a mixed column and a child `S` has height two, a seed of `C` in
that column must lie outside `S`'s rows, by Section 1. It occupies the only
remaining row. That seed and `B` span the full-height rectangle over `S`'s
column interval. Section 1 says this rectangle contains no initial seeds
other than `B` and that one seed. Section 2 excludes outside crowded columns.
The total is therefore at most one crowded column from `B`, plus one.

If both children have height one, their rows must be the top and bottom
rows. A mixed column has seeds at both ends, which infect its middle site.
It becomes a full-height strip, giving at most one crowded column by Section
2. This proves the height-three bound of two in every case.

## 6. Height Four

Apply Section 4 again.

**No mixed column.** Both children have height at most three. Section 5
bounds their crowded-column counts by two each, so the total is at most four.

**A mixed column, and a height-three child.** Let that child be `S`. The
other child's seed in a mixed column must lie in the unique row outside
`S`, by Section 1. Together with `B`, it fills a full-height strip over
`S`'s column interval. Sections 1 and 2 imply that all crowded columns come
from `B` plus this single extra seed: at most `2+1=3`.

**A mixed column, but no height-three child.** The children have height at
most two. At least one has height two, since two height-one rectangles
covering the top and bottom rows are at distance at least three and cannot
merge. A height-two child `S` must occupy the top two or bottom two rows:
an interior two-row child together with any other child of height at most
two cannot have a height-four bounding rectangle.

The rows outside `S` are therefore exactly the two rows on one side. Seeds
of `C` cannot lie inside `S`, by Section 1. Section 3 therefore allows at most
one seed of `C` within `S`'s column interval. Hence there
is at most one mixed column. The two children each contribute at most one
crowded column, and mixing contributes at most one more: a total of at most
`1+1+1=3`.

These cases exhaust all possibilities and prove the upper bound four.

## 7. Necessary Structure When Four Is Attained

The proof gives a stronger necessary condition. If `A` has four crowded
columns, its first full-height merge has no mixed column. Both children must
have height three and exactly two crowded columns. Their row intervals are
the top three rows and the bottom three rows.

Their column intervals must be disjoint. Otherwise, observe first that `C`
cannot have any seed with column in `S`'s interval: such a seed would lie
outside `S`'s rows by Section 1, and hence fill a full-height strip with
`B`, giving at most three crowded columns as in Section 6. Similarly `B`
has no seed with column in `T`'s interval. But internally spanning a rectangle
requires a seed in each of its end columns. Two overlapping column intervals
have an endpoint of one inside the other, a contradiction.

The two column intervals are thus separated by zero or one column, since
the children merge at distance at most two and their row intervals overlap.
If there is an intervening column, it contains no seed: it is in `R` but in
neither child. Each child is a minimal three-row set with two crowded columns;
outside `R`, every column has at most one seed.

This is necessary, not sufficient. For example, the height-four word
`[3,0,6,0,6,0,12]` glues two minimal three-row, two-crowded-column sets and
percolates, but is not minimal: its seed at `(3,5)` is redundant. Global
minimality, used throughout the proof, cannot be dropped.

## 8. Explicit Sharpness Without a Simulator Trace

Use the seed word

```text
[3,0,4,0,6,0,1,0,8,0,2,0,6,0,12].
```

Bit zero is the top row. Its four crowded columns are `1,5,13,15`.
The following rectangle filling proves percolation. On the left, the seeds
span rows `2..3`, columns `3..5`; merging with the pair in column 1 spans
rows `1..3`, columns `1..5`, and the seed in column 7 extends this to
columns `1..7`. On the right, the seeds span rows `2..3`, columns `11..13`;
the pair in column 15 extends this to rows `2..4`, columns `11..15`, and
the seed in column 9 extends it to columns `9..15`. The two three-row
rectangles are at distance two and fill the entire grid.

To verify minimality, a fort is a nonempty set of cells each having at most
one grid neighbor outside it. If a fort contains no initial seed, no cell
in it can ever become infected. The table gives such a fort for each deleted
seed. Entries are column masks of **empty fort cells**, not infected cells.
Each fort contains the deleted seed, avoids every remaining seed, and has
the stated local neighbor property.

| Deleted seed | Fort columns |
|---|---|
| (1,1) | [9,9,9,9,9,15,14,15,1,1,1,1,1,1,1] |
| (2,1) | [14,15,9,9,9,15,14,15,1,1,1,1,1,1,1] |
| (3,3) | [12,15,15,15,9,15,14,15,1,1,1,1,1,1,1] |
| (2,5) | [12,15,11,11,11,15,14,15,1,1,1,1,1,1,1] |
| (3,5) | [12,15,11,15,13,15,14,15,1,1,1,1,1,1,1] |
| (1,7) | [8,8,8,8,8,15,15,15,1,1,1,1,1,1,1] |
| (4,9) | [8,8,8,8,8,8,8,15,15,15,1,1,1,1,1] |
| (2,11) | [8,8,8,8,8,8,8,15,7,15,15,15,1,1,1] |
| (2,13) | [8,8,8,8,8,8,8,15,7,15,13,15,3,3,3] |
| (3,13) | [8,8,8,8,8,8,8,15,7,15,13,13,13,15,3] |
| (3,15) | [8,8,8,8,8,8,8,15,7,15,9,9,9,15,7] |
| (4,15) | [8,8,8,8,8,8,8,15,7,15,9,9,9,9,9] |

This establishes the sharp constant four using an explicit finite example.
The infinite sharpness family in the earlier note remains separately
computer-assisted; its pumping argument is not needed for this theorem.

## Validation and Remaining Review

`test/rectangle_merge_proof.jl` tests the rectangle merge and single-seed
extension facts, the full-height-strip propagation construction, and the
no-outside-seed lemmas. It checks every configuration of `2 x 4`, `3 x 4`,
and `4 x 4` against direct closure. For minimal sets it also checks seed
ownership, child minimality, and the stronger mixed-column bound. The explicit
fort table is stored in `experiments/results/width4_crowded_sharp_forts.toml`
and is verified only by its local constraints, without simulating infection.

These tests corroborate the proof; they are not the all-width justification.
That justification is Sections 1--6. The standard rectangles process must be
credited, and neither a new proof nor an unlocated statement establishes
priority. External mathematical and literature review remain necessary.
