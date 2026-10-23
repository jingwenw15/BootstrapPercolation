include("../experiments/rectangle_merge_proof.jl")
using TOML
if !@isdefined(fast_closure)
    include("../experiments/fast_exact.jl")
end
if !@isdefined(is_minimal_percolating)
    include("../src/minimal.jl")
end

function proof_rectangle_mask(height, width, bounds)
    mask = UInt64(0)
    for row in bounds[1]:bounds[2], col in bounds[3]:bounds[4]
        mask |= UInt64(1) << bit_index(height, width, row, col)
    end
    return mask
end

@testset "Geometric Crowded-Column Proof Lemmas" begin
    height, width = 4, 5
    rectangles = [(top, bottom, left, right) for top in 1:height for bottom in top:height
                  for left in 1:width for right in left:width]
    neighbors = neighbor_masks(height, width)
    masks = [proof_rectangle_mask(height, width, rectangle) for rectangle in rectangles]
    for i in eachindex(rectangles), j in i:length(rectangles)
        rectangle_l1_distance(rectangles[i], rectangles[j]) <= 2 || continue
        expected = proof_rectangle_mask(height, width, rectangle_hull(rectangles[i], rectangles[j]))
        @test fast_closure(height, width, masks[i] | masks[j], neighbors) == expected
    end
    for (rectangle, mask) in zip(rectangles, masks), row in 1:height, col in rectangle[3]:rectangle[4]
        vertical_distance = max(rectangle[1] - row, row - rectangle[2], 0)
        vertical_distance in 1:2 || continue
        extra = UInt64(1) << bit_index(height, width, row, col)
        expected = proof_rectangle_mask(height, width, rectangle_hull(rectangle, (row, row, col, col)))
        @test fast_closure(height, width, mask | extra, neighbors) == expected
    end

    # One seed per occupied column propagates from a full-height strip if
    # the endpoints are occupied and no two consecutive columns are empty.
    for height in 1:4, width in 1:5
        neighbors = neighbor_masks(height, width)
        for encoded in 0:((height + 1)^width - 1)
            digits = [mod(div(encoded, (height + 1)^(col - 1)), height + 1) for col in 1:width]
            digits[1] != 0 && digits[end] != 0 || continue
            any(col -> digits[col] == digits[col + 1] == 0, 1:(width - 1)) && continue
            seeds = UInt64(0)
            for col in 1:width
                digits[col] == 0 && continue
                seeds |= UInt64(1) << bit_index(height, width, digits[col], col)
            end
            for left in 1:width, right in left:width
                strip = proof_rectangle_mask(height, width, (1, height, left, right))
                @test fast_percolates(height, width, seeds | strip, neighbors)
            end
        end
    end
end

@testset "Rectangle Proof on Every Small Configuration" begin
    for (height, width) in ((2, 4), (3, 4), (4, 4))
        neighbors = neighbor_masks(height, width)
        rectangles = [(top, bottom, left, right) for top in 1:height for bottom in top:height
                      for left in 1:width for right in left:width]
        for mask in UInt64(0):((UInt64(1) << (height * width)) - UInt64(1))
            grid = bitmask_to_grid(height, width, mask)
            tree = rectangle_merge_tree(grid)
            union_mask = UInt64(0)
            for id in tree.active
                union_mask |= proof_rectangle_mask(height, width, tree.nodes[id].bounds)
            end
            @test union_mask == fast_closure(height, width, mask, neighbors)
            fast_is_minimal_percolating(height, width, mask, neighbors) || continue
            split = first_full_height_merge(grid; tree = tree)
            @test Set(split.node.seeds) == Set(filter(cell -> rectangle_contains(split.node.bounds, cell), findall(==("X"), grid)))
            for child in (split.left, split.right)
                @test Set(child.seeds) == Set(filter(cell -> rectangle_contains(child.bounds, cell), findall(==("X"), grid)))
                @test is_minimal_percolating(rectangle_node_grid(child))
            end
            for rectangle in rectangles
                inside = proof_rectangle_mask(height, width, rectangle)
                fast_closure(height, width, mask & inside, neighbors) == inside || continue
                for direction in (-1, 1)
                    edge = direction == -1 ? rectangle[1] : rectangle[2]
                    count_outside = 0
                    for distance in 1:2
                        row = edge + direction * distance
                        1 <= row <= height || continue
                        for col in rectangle[3]:rectangle[4]
                            count_outside += Int((mask & (UInt64(1) << bit_index(height, width, row, col))) != 0)
                        end
                    end
                    @test count_outside <= 1
                end
                if rectangle[1] == 1 && rectangle[2] == height
                    for col in 1:width
                        rectangle[3] <= col <= rectangle[4] && continue
                        @test count(row -> (mask & (UInt64(1) << bit_index(height, width, row, col))) != 0, 1:height) <= 1
                    end
                end
            end
            bound = height == 2 ? 1 : height == 3 ? 2 : 4
            @test rectangle_seed_crowded_count(findall(==("X"), grid)) <= bound
            if !isempty(split.mixed_columns) && height == 4
                @test rectangle_seed_crowded_count(findall(==("X"), grid)) <= 3
            end
        end
    end

    # This sharp example has four crowded columns, so the proof predicts two
    # separated three-row children with exactly two crowded columns each.
    word = [3, 0, 4, 0, 6, 0, 1, 0, 8, 0, 2, 0, 6, 0, 12]
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in word]
    original = copy(grid)
    split = first_full_height_merge(grid)
    @test is_minimal_percolating(grid)
    @test grid == original
    @test isempty(split.mixed_columns)
    @test all(child -> rectangle_height(child.bounds) == 3, (split.left, split.right))
    @test all(child -> rectangle_seed_crowded_count(child.seeds) == 2, (split.left, split.right))
    @test split.left.bounds[4] < split.right.bounds[3] || split.right.bounds[4] < split.left.bounds[3]
    @test_throws ArgumentError rectangle_merge_tree(fill("?", 2, 2))
    @test_throws ArgumentError first_full_height_merge(fill(".", 4, 4))

    not_minimal = [3, 0, 6, 0, 6, 0, 12]
    counterexample = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in not_minimal]
    @test percolates(counterexample)
    @test !is_minimal_percolating(counterexample)
    counterexample[3, 5] = "."
    @test percolates(counterexample)
end

@testset "Explicit Sharpness Forts Without Simulation" begin
    report = TOML.parsefile(joinpath(@__DIR__, "..", "experiments", "results", "width4_crowded_sharp_forts.toml"))
    word = report["seed_columns"]
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in word]
    covered = Set{CartesianIndex{2}}()
    proof = read(joinpath(@__DIR__, "..", "notes", "width4_crowded_hand_proof.md"), String)
    for deletion in report["deletions"]
        row, col = deletion["row"], deletion["column"]
        removed = CartesianIndex(row, col)
        fort = deletion["fort_columns"]
        @test verify_deletion_fort_columns(grid, removed, fort)
        @test !(removed in covered)
        push!(covered, removed)
        @test occursin("| ($(row),$(col)) | [$(join(fort, ','))] |", proof)
    end
    @test covered == Set(findall(==("X"), grid))
    @test !verify_deletion_fort_columns(grid, CartesianIndex(1, 1), zeros(Int, 15))
    @test !verify_deletion_fort_columns(grid, CartesianIndex(1, 1), fill(15, 15))
    @test !verify_deletion_fort_columns(grid, CartesianIndex(1, 1), fill(16, 15))
    @test !verify_deletion_fort_columns(grid, CartesianIndex(1, 1), [1; zeros(Int, 14)])
    @test !verify_deletion_fort_columns(grid, CartesianIndex(1, 2), zeros(Int, 15))
    @test !verify_deletion_fort_columns(grid, CartesianIndex(1, 1), zeros(Int, 14))
end

@testset "Two-Arm Structure in the Infinite Sharpness Family" begin
    family = TOML.parsefile(joinpath(@__DIR__, "..", "experiments", "results", "width4_crowded_columns.toml"))["pumping_family"]
    for copies in 1:4
        word = vcat(family["left"], repeat(family["block"], copies), family["right"])
        grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in word]
        @test is_minimal_percolating(grid)
        split = first_full_height_merge(grid)
        @test isempty(split.mixed_columns)
        @test all(child -> rectangle_height(child.bounds) == 3, (split.left, split.right))
        @test all(child -> rectangle_seed_crowded_count(child.seeds) == 2, (split.left, split.right))
        @test split.left.bounds[4] < split.right.bounds[3] || split.right.bounds[4] < split.left.bounds[3]
    end
end
