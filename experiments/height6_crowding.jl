if !@isdefined(height5_sharp_columns)
    include("height5_crowding.jl")
end

"""Find the full-three-row subrectangle used in the overlap lemma's proof."""
function three_row_overlap_nucleus(node, other)
    rectangle_height(node.bounds) == rectangle_height(other.bounds) == 3 ||
        throw(ArgumentError("both strips must have height three"))
    below = other.bounds[1] == node.bounds[2] + 1
    above = other.bounds[2] == node.bounds[1] - 1
    below || above || throw(ArgumentError("the strips must be vertically adjacent"))
    split = first_full_height_merge(rectangle_node_grid(node))
    children = (split.left, split.right)
    far_top = below ? 1 : 2
    far = findfirst(child -> rectangle_height(child.bounds) == 2 && child.bounds[1] == far_top, children)
    if far !== nothing
        candidate, kind, cap = split.node, "far_two_row_child", 3
    else
        near = findfirst(child -> rectangle_height(child.bounds) == 2, children)
        if near !== nothing
            strip, line = children[near], children[3 - near]
            index = findfirst(cell -> rectangle_l1_distance(strip.bounds, (cell[1], cell[1], cell[2], cell[2])) <= 2, line.seeds)
            index === nothing && error("the one-row child has no nearby endpoint seed")
            cell = line.seeds[index]
            candidate = RectangleMergeNode(rectangle_hull(strip.bounds, (cell[1], cell[1], cell[2], cell[2])),
                                           vcat(strip.seeds, cell), (0, 0))
            kind, cap = "near_two_row_child", 2
        else
            column = max(children[1].bounds[3], children[2].bounds[3])
            column <= min(children[1].bounds[4], children[2].bounds[4]) || error("the one-row children do not overlap")
            seeds = CartesianIndex{2}[]
            for child in children
                row = child.bounds[1]
                if CartesianIndex(row, column) in child.seeds
                    push!(seeds, CartesianIndex(row, column))
                else
                    for col in (column - 1, column + 1)
                        cell = CartesianIndex(row, col)
                        cell in child.seeds || error("a one-row spanning interval has a double gap")
                        push!(seeds, cell)
                    end
                end
            end
            bounds = (1, 3, minimum(cell[2] for cell in seeds), maximum(cell[2] for cell in seeds))
            candidate = RectangleMergeNode(bounds, seeds, (0, 0))
            kind, cap = "two_one_row_children", 4
        end
    end
    row_offset, col_offset = node.bounds[1] - 1, node.bounds[3] - 1
    bounds = (candidate.bounds[1] + row_offset, candidate.bounds[2] + row_offset,
              candidate.bounds[3] + col_offset, candidate.bounds[4] + col_offset)
    seeds = [cell + CartesianIndex(row_offset, col_offset) for cell in candidate.seeds]
    return (node = RectangleMergeNode(bounds, seeds, (0, 0)), case = kind, overlap_seed_bound = cap)
end

"""A constructive redundancy check; nothing is not a claim of minimality."""
function three_row_overlap_redundant_seed(node, other)
    nucleus = three_row_overlap_nucleus(node, other).node
    inside = [cell for cell in node.seeds if other.bounds[3] <= cell[2] <= other.bounds[4]]
    overlap = max(nucleus.bounds[3], other.bounds[3]) <= min(nucleus.bounds[4], other.bounds[4])
    if overlap
        candidates = filter(cell -> !(cell in nucleus.seeds), inside)
    else
        length(inside) >= 2 || return nothing
        sort!(inside; by = cell -> (min(abs(cell[2] - nucleus.bounds[3]), abs(cell[2] - nucleus.bounds[4])), cell[2], cell[1]))
        candidates = inside[2:end]
    end
    return isempty(candidates) ? nothing : first(candidates)
end

function height6_crowding_case(grid; check_minimal = true)
    size(grid, 1) == 6 || throw(ArgumentError("height must be six"))
    check_minimal && !is_minimal_percolating(grid) && throw(ArgumentError("the grid is not minimal percolating"))
    split = first_full_height_merge(grid)
    heights = (rectangle_height(split.left.bounds), rectangle_height(split.right.bounds))
    if isempty(split.mixed_columns)
        limits = (0, 1, 2, 4, 8)
        bound, kind = limits[heights[1]] + limits[heights[2]], "no_mixed_column"
    elseif maximum(heights) == 5
        bound, kind = 9, "height_five_child"
    elseif maximum(heights) == 4
        bound, kind = 9, "height_four_child"
    elseif heights == (3, 3)
        bound, kind = 8, "adjacent_three_row_children"
    elseif sort(collect(heights)) == [2, 3]
        bound, kind = 5, "separated_two_and_three_row_children"
    else
        error("impossible first full-height merge")
    end
    return (case = kind, bound = bound, split = split,
            crowded = rectangle_seed_crowded_count(findall(==("X"), grid)))
end

function height6_sharp_columns()
    arm = vcat(height5_sharp_columns(), [0, 1])
    reflected = [sum(((column >> (row - 1)) & 1) << (5 - row) for row in 1:5) << 1
                 for column in reverse(arm)]
    return vcat(arm, [0], reflected)
end

"""Specialization of Gottschau (2020), Lemmas 50--51 and Figure 3.5."""
function gottschau_height7_columns(k)
    k >= 1 || throw(ArgumentError("k must be positive"))
    columns = zeros(Int, 3 * k + 2)
    for i in 0:(k - 1), col in (3 * i + 2, 3 * i + 4)
        columns[col] |= 1 | (1 << 6)
    end
    for (row, col) in ((2, 2), (6, length(columns) - 1), (3, length(columns)), (5, 1))
        columns[col] |= 1 << (row - 1)
    end
    return columns
end

function write_height6_crowding_certificate(path = joinpath(@__DIR__, "results", "height6_crowding.toml"))
    columns = height6_sharp_columns()
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:6, column in columns]
    percolates(grid) || error("the height-six witness does not percolate")
    deletions = Dict{String, Any}[]
    for cell in findall(==("X"), grid)
        removed = copy(grid)
        removed[cell] = "."
        final, percolated, _, _ = simulate(removed)
        percolated && error("the height-six witness has a redundant seed")
        fort = [sum(Int(final[row, col] == ".") << (row - 1) for row in 1:6) for col in axes(grid, 2)]
        verify_deletion_fort_columns(grid, cell, fort) || error("invalid height-six deletion fort")
        push!(deletions, Dict("row" => cell[1], "column" => cell[2], "fort_columns" => fort))
    end
    shape = height6_crowding_case(grid; check_minimal = false)
    shape.crowded == shape.bound == 16 || error("the sharp crowded-column count is incorrect")
    report = Dict("height" => 6, "width" => length(columns), "seed_count" => count(==("X"), grid),
                  "crowded_columns" => 16, "all_width_upper_bound" => 16, "seed_columns" => columns,
                  "deletions" => deletions, "threshold_height" => 7,
                  "upper_bound_is_geometric_proof_not_finite_search" => true,
                  "height7_source" => "Gottschau (2020), Lemmas 50--51, Figure 3.5; existing construction")
    open(path, "w") do io
        println(io, "# Height-six sharpness data; the all-width proof is in notes/height6_crowding.md.")
        TOML.print(io, report; sorted = true)
    end
    return report
end

if abspath(PROGRAM_FILE) == @__FILE__
    report = write_height6_crowding_certificate(isempty(ARGS) ? joinpath(@__DIR__, "results", "height6_crowding.toml") : ARGS[1])
    println("height-six crowded-column bound = ", report["all_width_upper_bound"])
    println("sharp witness: ", report["width"], " columns; ", report["seed_count"], " seeds")
    println("locally verified deletion forts = ", length(report["deletions"]))
end
