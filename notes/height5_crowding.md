# Height Five Still Has Bounded Crowding

Proof draft, 2026-10-23. No novelty or external-review claim is made.

Update, 2026-10-25: the next stage proves `M(6)=16` and reproduces Gottschau's
known unbounded height-seven family, identifying the threshold as seven.
See `notes/height6_crowding.md`. The range below records the earlier stage;
it is no longer the sharpest conclusion.

## Result and Research Target

A crowded column contains at least two initial seeds. Let `M(h)` be the
supremum of the number of crowded columns over all inclusion-minimal
percolating sets on all finite `h x n` grids, with `n` unrestricted.

**Theorem.** `M(5)=8`: every minimal percolating set on every five-row grid
has at most eight crowded columns, and a `5 x 35` example attains eight.

Together with our earlier bounds and their small sharp examples, the values
through height five are

```text
h       1  2  3  4  5
M(h)    0  1  2  4  8.
```

The height-two and height-three bounds are attained by the seed words `[3]`
and `[3,0,6]`, respectively, with bit zero denoting the top row.

The smallest height `h*` at which `M(h)` is infinite therefore satisfies

```text
6 <= h* <= 8.
```

The upper endpoint comes from Morris's existing height-eight construction,
not a new construction here. Heights six and seven remain unresolved in
this project. The finite sequence above must not be extrapolated to those
heights. This statement concerns crowded columns in **all** minimal sets;
it is not an exact formula for the largest seed count `E(5,n)`.

## Ingredients Already Established

We use the direct proof in `notes/width4_crowded_hand_proof.md`, rather than
any computed state graph. In particular:

- A minimal set cannot contain a seed recoverable from its other seeds.
- If a subset internally spans a rectangle, it consists of exactly the
  original seeds in that rectangle and is minimal on the rectangle.
- A full-height internally spanned strip confines all crowded columns to
  that strip's column interval.
- At most one seed can lie in the two rows immediately on either side of
  an internally spanned rectangle, within its column interval. This bound
  applies separately above and below.
- The sharp crowded-column bounds at heights at most four are `0,1,2,4`.

Run the classical rectangles process, retaining disjoint ownership of the
initial seeds. At the first five-row rectangle, its children `S,T` have
heights at most four and owning seed sets `B,C`. Their bounding rectangle
contains exactly `B union C` from the initial set. All crowded columns of
the whole initial set lie in this rectangle. A mixed column contains a seed
from both `B` and `C`.

## The New Two-Row Bridge Lemma

**Lemma.** Suppose the two children have height two and their bounding
rectangle has height five. In a globally minimal set, they have at most two
mixed columns.

Their row intervals must be rows `1..2` and `4..5`, up to reflection. The
vertical distance is two, so their column intervals must overlap for the
rectangles to merge.

First recall the elementary two-row anchor fact: every internally spanning
two-row set contains two seeds in opposite rows whose columns differ by
at most one. These seeds fill a two-row rectangle with column interval `I`
of width at most two. This fact is used in
[Morris (2009), proof of Theorem 9(b)](https://www.combinatorics.org/ojs/index.php/eljc/article/download/v16i1r2/pdf/).
It is an existing ingredient, not a new claim.

One way to see the anchor fact is to take the first height-two merge in
the rectangles process. Its children are one-row internally spanned
intervals. If their column intervals are disjoint, the nearest endpoint
seeds differ by at most one column. If the intervals overlap, an endpoint
seed of one lies in the other's interval; the latter has no two consecutive
empty positions, so it has a seed within one column of that endpoint.

Choose an anchor from `B`, and write `J` for `T`'s column interval.

**Case 1: `I` intersects `J`.** The filled anchor and `T` are at vertical
distance two with overlapping columns. They fill a height-five rectangle
containing all columns of `J`. Any seed of `B` whose column is in `J`, other
than the two anchor seeds, is therefore recoverable from the anchor and
`C`. Global minimality forbids it. All mixed columns must consequently be
among the at most two anchor columns.

**Case 2: `I` and `J` are disjoint.** All columns of `J` are on the same
side of the anchor. If two mixed columns existed, call the nearer one `x`
and the farther one `y`. Delete a seed of `B` in column `y`.

The anchor together with the seeds of `B` between the anchor and `x` still
fills the two-row interval as far as `x`. Indeed, `B` internally spans its
two-row rectangle, so its occupied columns have no double empty gap; from
the filled anchor one can advance to each next occupied column, one or two
columns away. This uses no seed in the farther column `y`.

The resulting two-row rectangle overlaps `J` at `x`. Together with the
unchanged filled `T`, it spans a height-five rectangle containing all of
`J`, including the deleted seed's position. That seed is recovered from
the others, contradicting minimality. Thus this case has at most one mixed
column, proving the lemma.

In fact this argument bounds the number of seeds of `B` in `J` by two,
whether or not their columns initially contain a seed of `C`. If two such
seeds share a column outside the anchor, extending the filled two-row
interval to either seed also recovers the other.

## Proof of the Eight-Column Upper Bound

Use the first full-height merge described above.

1. **No mixed column.** Each child has at most four crowded columns by the
   height-four theorem. The total is at most `4+4=8`.
2. **A mixed column and a height-four child.** A seed of the other child
   in that column lies outside the four-row child and fills its missing
   fifth row. The resulting full-height strip contains only that child's
   seeds plus this one seed, and excludes outside crowded columns. The
   total is at most `4+1=5`.
3. **A mixed column, with maximum child height three.** A three-row child
   must occupy the top three or bottom three rows: an interior three-row
   interval and another interval of height at most three cannot together
   reach both outer rows. All other-child seeds in its column interval lie
   outside it, on the same side within two rows. The one-sided seed cap
   permits at most one, hence at most one mixed column. Each child has at
   most two crowded columns, giving at most `2+2+1=5`.
4. **A mixed column, with maximum child height two.** Both children must
   have height two: a height-two and height-one pair spanning five rows
   have distance at least three and cannot merge. Apply the bridge lemma.
   The children have at most one crowded column each and mixing adds at
   most two, giving at most `1+1+2=4`.

Smaller children cannot merge to span five rows. These cases exhaust all
possibilities and establish the bound for every width, without a finite
search cutoff.

If eight is attained, the first full-height merge necessarily has two
four-row children with four crowded columns each and no mixed column.
Their column intervals are disjoint. Any seed of either child inside the
other's column interval would fill that child's missing row and force a
bound of five instead; overlapping intervals have an endpoint seed in the
other interval. This is a necessary condition, not a complete classification.

## A Sharp Finite Witness

Let

```text
W = [3,0,4,0,6,0,1,0,8,0,2,0,6,0,12]
U = W followed by [0,1].
```

`W` is the earlier four-crowded-column, four-row example. Put `U` in the
top four rows, leave one empty column, and put a 180-degree-rotated copy of
`U` in the bottom four rows. Bit zero denotes the top row of the grid.
The resulting five-row seed word is

```text
[3,0,4,0,6,0,1,0,8,0,2,0,6,0,12,0,1,0,
 16,0,6,0,12,0,8,0,2,0,16,0,12,0,4,0,24].
```

It has width 35, 26 seeds, and eight crowded columns. Each four-row arm
fills: `W` spans its original rectangle, and the added seed two columns
away extends it. The two four-row arms then merge across the empty middle
column, filling the entire grid.

Minimality is witnessed by the 26 explicit deletion forts in
`experiments/results/height5_crowding.toml`. Every fort contains its deleted
seed, avoids all remaining seeds, and gives each of its cells at most one
grid neighbor outside the fort. These are finite local constraints: each
deleted configuration leaves a nonempty permanently empty set. The tests
check those constraints without simulation, and separately check percolation
and every seed deletion with the original simulator. This proves sharpness.
We do not assert that 26 is `E(5,35)`.

## Why the Threshold Is at Most Eight

[Morris (2009), Lemma 3](https://www.combinatorics.org/ojs/index.php/eljc/article/download/v16i1r2/pdf/)
constructs minimal percolating sets on an `8 x (3k+2)` rectangle with `4k+4`
seeds. Orient the short side vertically. Inspection of his explicit seed
positions gives crowded columns `1,3,6,...,3k,3k+2`, exactly `k+2` of them.
Thus `M(8)` is infinite. This known construction is reproduced, with clear
attribution, by `morris_height8_columns(k)`; it is not a new result here.

The new height-five bound rules out the previous candidate height five.
At this stage the remaining question was whether the smallest unbounded
height was six, seven, or eight. The subsequent height-six proof resolves
this as seven; the height-seven upper endpoint comes from existing work.

## Reproduction, Tests, and Priority

```text
julia --project=. experiments/height5_crowding.jl
julia --project=. test/runtests.jl
```

The experiment constructs the witness and generates all deletion forts.
The tests exhaust all five-row grids through width four, check the proof's
case bounds on every minimal configuration found, test two-row anchors, and
check the bridge lemma's explicitly removable seeds on overlapping pairs of
two-row minimal sets in both orientations. They also verify the sharp
witness and reproduce Morris's construction for `k=1,...,6`. These finite
tests support, but do not replace, the all-width geometric proof.

The targeted literature search did not locate this crowded-column bound or
the exact smallest-unbounded-height question. It checked variants of
minimal percolating, bounded columns, height five, and thin strips. Indexed
primary passages of Gottschau's dissertation about corner-avoiding sets and
the grid bounds were inspected, but direct retrieval of the full PDF again
returned HTTP 429. That is not a complete priority review. The two-row
anchor fact and height-eight family belong to Morris; the rectangles process
is classical. Novelty and external mathematical review remain unresolved.
