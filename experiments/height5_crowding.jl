using TOML
if !@isdefined(RectangleMergeNode)
    include("rectangle_merge_proof.jl")
end
if !@isdefined(is_minimal_percolating)
    include("../src/minimal.jl")
end

function two_row_seed_anchor(node)
    rectangle_height(node.bounds) == 2 || throw(ArgumentError("a two-row rectangle is required"))
    for first in node.seeds, second in node.seeds
        first[1] != second[1] && abs(first[2] - second[2]) <= 1 || continue
        bounds = rectangle_hull((first[1], first[1], first[2], first[2]),
                                (second[1], second[1], second[2], second[2]))
        return (seeds = (first, second), bounds = bounds)
    end
    throw(ArgumentError("the two-row seed set has no spanning anchor"))
end

"""
Find the removable seed supplied by the separated-two-row-strip lemma.
`split` must come from a percolating five-row grid with two height-two
children. Returning nothing does not assert that the configuration is minimal.
"""
function separated_two_row_redundant_seed(split)
    left, right = split.left, split.right
    rectangle_height(left.bounds) == rectangle_height(right.bounds) == 2 ||
        throw(ArgumentError("both children must have height two"))
    rectangle_height(rectangle_hull(left.bounds, right.bounds)) == 5 ||
        throw(ArgumentError("the two strips must span five rows"))
    rectangle_l1_distance(left.bounds, right.bounds) <= 2 ||
        throw(ArgumentError("the two strips cannot merge"))
    anchor = two_row_seed_anchor(left)
    lo, hi = anchor.bounds[3], anchor.bounds[4]
    overlaps = max(lo, right.bounds[3]) <= min(hi, right.bounds[4])
    if overlaps
        candidates = filter(col -> !(lo <= col <= hi), split.mixed_columns)
        isempty(candidates) && return nothing
        column = first(candidates)
    else
        length(split.mixed_columns) >= 2 || return nothing
        column = right.bounds[4] < lo ? minimum(split.mixed_columns) : maximum(split.mixed_columns)
    end
    return first(cell for cell in left.seeds if cell[2] == column)
end

function height5_crowding_case(grid; check_minimal = true)
    size(grid, 1) == 5 || throw(ArgumentError("height must be five"))
    check_minimal && !is_minimal_percolating(grid) && throw(ArgumentError("the grid is not minimal percolating"))
    split = first_full_height_merge(grid)
    height = max(rectangle_height(split.left.bounds), rectangle_height(split.right.bounds))
    if isempty(split.mixed_columns)
        bounds = (0, 1, 2, 4)
        bound = bounds[rectangle_height(split.left.bounds)] + bounds[rectangle_height(split.right.bounds)]
        name = "no_mixed_column"
    elseif height == 4
        bound, name = 5, "height_four_child"
    elseif height == 3
        bound, name = 5, "height_three_child"
    elseif height == 2
        bound, name = 4, "separated_two_row_children"
    else
        error("impossible first full-height merge")
    end
    crowded = rectangle_seed_crowded_count(findall(==("X"), grid))
    return (case = name, bound = bound, crowded = crowded, split = split)
end

function height5_sharp_columns()
    base = [3, 0, 4, 0, 6, 0, 1, 0, 8, 0, 2, 0, 6, 0, 12]
    arm = vcat(base, [0, 1])
    reflected = [sum(((column >> (row - 1)) & 1) << (4 - row) for row in 1:4) << 1
                 for column in reverse(arm)]
    return vcat(arm, [0], reflected)
end

"""Morris (2009), Lemma 3, transposed to height eight; not a new construction."""
function morris_height8_columns(k)
    k >= 1 || throw(ArgumentError("k must be positive"))
    columns = zeros(Int, 3 * k + 2)
    for i in 0:(k - 1)
        columns[3 * i + 1] |= 1
        columns[3 * i + 3] |= 1
        columns[3 * i + 3] |= 1 << 7
        columns[3 * i + 5] |= 1 << 7
    end
    for (row, col) in ((2, 3 * k), (4, 1), (5, 3 * k + 2), (7, 3))
        columns[col] |= 1 << (row - 1)
    end
    return columns
end

function write_height5_crowding_certificate(path = joinpath(@__DIR__, "results", "height5_crowding.toml"))
    columns = height5_sharp_columns()
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:5, column in columns]
    percolates(grid) || error("the eight-crowded-column witness does not percolate")
    deletions = Dict{String, Any}[]
    for cell in findall(==("X"), grid)
        removed = copy(grid)
        removed[cell] = "."
        final, percolated, _, _ = simulate(removed)
        percolated && error("the height-five witness has a redundant seed")
        fort = [sum(Int(final[row, col] == ".") << (row - 1) for row in 1:5) for col in axes(grid, 2)]
        verify_deletion_fort_columns(grid, cell, fort) || error("invalid local deletion fort")
        push!(deletions, Dict("row" => cell[1], "column" => cell[2], "fort_columns" => fort))
    end
    shape = height5_crowding_case(grid; check_minimal = false)
    shape.crowded == shape.bound == 8 || error("the sharp witness has the wrong crowded-column count")
    report = Dict(
        "height" => 5, "width" => length(columns), "seed_count" => count(==("X"), grid),
        "crowded_columns" => shape.crowded, "all_width_upper_bound" => 8,
        "upper_bound_is_geometric_proof_not_finite_search" => true,
        "seed_columns" => columns, "deletions" => deletions,
        "first_full_height_merge_case" => shape.case,
        "child_heights" => [rectangle_height(child.bounds) for child in (shape.split.left, shape.split.right)],
        "child_crowded_columns" => [rectangle_seed_crowded_count(child.seeds) for child in (shape.split.left, shape.split.right)],
        "threshold_lower_bound" => 6, "threshold_upper_bound_from_morris" => 8,
    )
    open(path, "w") do io
        println(io, "# Sharp height-five crowding witness and explicit local seed-deletion forts.")
        println(io, "# The all-width upper bound is proved in notes/height5_crowding.md, not inferred from samples.")
        TOML.print(io, report; sorted = true)
    end
    return report
end

if abspath(PROGRAM_FILE) == @__FILE__
    report = write_height5_crowding_certificate(isempty(ARGS) ? joinpath(@__DIR__, "results", "height5_crowding.toml") : ARGS[1])
    println("all-width height-five crowded-column bound = ", report["all_width_upper_bound"])
    println("sharp witness width = ", report["width"], "; seeds = ", report["seed_count"],
            "; crowded columns = ", report["crowded_columns"])
    println("each seed deletion has a locally verified fort: ", length(report["deletions"]))
end
