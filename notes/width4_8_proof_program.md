# Proof Program For E(4,8) = 8

This note separates the certified computational result from the desired
human-readable proof.

## Certified Result

The exact search proves:

```text
E(4,8) = 8.
```

The computation checks all candidate sets of sizes 10, 9, and 8 in descending
order from Morris's upper bound:

```text
Morris upper bound for 4 x 8 = floor((4 + 2)(8 + 2) / 6) = 10.
```

The exact search found:

```text
size 10: no minimal percolating sets
size 9:  no minimal percolating sets
size 8:  7,074 minimal percolating sets
```

Thus the computational certificate is complete.

## Desired Mathematical Proof

To prove `E(4,8) = 8` without exhaustive enumeration, it is enough to prove two
claims.

### Lower Bound

Exhibit one inclusion-minimal percolating set of size 8 on `4 x 8`.

For example:

```text
X X . X X . X X
. . . . . . . .
X . . . . . . .
X . . . . . . .
```

The simulator verifies that this set is inclusion-minimal percolating.

### Upper Bound

Prove that no size-9 set on `4 x 8` is inclusion-minimal percolating.

Equivalently, prove:

```text
Every size-9 set A either does not percolate, or some x in A is removable.
```

Here removable means:

```text
A \ {x} still percolates.
```

## What The Size-9 Layer Looks Like

The size-9 layer has:

```text
28,048,800 total sets
18,483,860 nonpercolating sets
 9,564,940 percolating sets
         0 minimal percolating sets
```

Among the percolating size-9 sets, the number of removable seeds is:

| removable seeds | count |
|----------------:|------:|
| 1 | 240 |
| 2 | 28,964 |
| 3 | 347,580 |
| 4 | 1,592,912 |
| 5 | 3,106,772 |
| 6 | 2,959,324 |
| 7 | 1,347,784 |
| 8 | 181,364 |

Therefore the extremal obstruction is concentrated in the 240 percolating sets
with exactly one removable seed.

## Critical Cases

The 240 critical cases reduce to 60 classes under row reversal and column
reversal.

The unique removable seed belongs to one of only six position orbits:

| removable-seed orbit | classes |
|----------------------|--------:|
| `(2,2), (2,7), (3,2), (3,7)` | 38 |
| `(2,4), (2,5), (3,4), (3,5)` | 12 |
| `(1,2), (1,7), (4,2), (4,7)` | 4 |
| `(2,1), (2,8), (3,1), (3,8)` | 3 |
| `(1,4), (1,5), (4,4), (4,5)` | 2 |
| `(1,3), (1,6), (4,3), (4,6)` | 1 |

So 50 of the 60 critical classes have the removable seed in one of two interior
orbits:

```text
(2,2), (2,7), (3,2), (3,7)
(2,4), (2,5), (3,4), (3,5)
```

## Candidate Proof Strategy

The goal is to prove:

```text
If A has 9 seeds and percolates on 4 x 8, then A has a removable seed.
```

A plausible proof route:

1. Show that any percolating size-9 set must contain enough seeds in the two
   middle rows to start infection in both halves of the rectangle.
2. Show that one such middle-row seed acts only as a trigger.
3. Once the process percolates, that trigger becomes redundant because the same
   infection wave can be initiated from neighboring seeds.
4. Handle boundary-trigger exceptions separately.

The computational data suggests the first split should be by the location of the
eventual removable seed, not by row profile or column profile. Row and column
profiles do not compress the 60 critical classes enough.

## Key Structural Lemma Candidate

For all 240 critical size-9 sets, the unique removable seed is reinfected at
time 1 after it is removed.

In symbols, if `A` is one of the critical sets and `x` is its unique removable
seed, then in the process started from `A \ {x}`, the cell `x` becomes infected
in the first synchronous round.

Computationally:

```text
removed seed reinfection time histogram:
  1: 240
```

This is a much stronger and cleaner statement than merely saying that some seed
is removable. It means the redundant seed is locally forced immediately by two
infected neighbors already present in `A \ {x}`.

So a possible proof of the critical cases is:

```text
Every critical size-9 percolating set on 4 x 8 has a seed x that is locally
forced by two other seeds.
```

If such an `x` can be identified structurally, then `x` is automatically
removable, because deleting `x` only delays that cell by one round and the rest
of the process can proceed afterward.

However, the stronger global local-redundancy claim is false. Among all
percolating size-9 sets on `4 x 8`, many have no initially infected cell with
two initially infected neighbors:

```text
percolating size-9 sets: 9,564,940
sets with zero locally forced seeds: 3,206,768
```

So a proof still needs a first reduction step: show that any putative
minimal-percolating size-9 set can be reduced to the critical situation, or show
directly that the non-critical percolating sets have removable seeds by a
different mechanism.

The local-redundancy report is saved in
`experiments/results/width4_4x8_size9_local_redundancy.txt`.

## Is This Novel?

The exact value `E(4,8) = 8` is outside the exact thin-rectangle cases stated by
Morris, which cover one dimension equal to 1, 2, or 3. A targeted search did not
find a published formula for `E(4,n)` or a tabulated value for `E(4,8)`.

That said, this should be described cautiously:

```text
plausibly novel computational result, not yet confirmed as a new theorem in the
literature.
```

The result becomes substantially stronger if we replace the exhaustive
enumeration certificate with a structural proof of the size-9 upper bound.
