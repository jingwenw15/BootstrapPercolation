include("../experiments/height5_crowding.jl")
if !@isdefined(fast_is_minimal_percolating)
    include("../experiments/fast_exact.jl")
end

@testset "Two-Row Anchors and the Height-Five Bridge Lemma" begin
    width = 4
    neighbors = neighbor_masks(2, width)
    minimal = Matrix{String}[]
    for mask in UInt64(0):((UInt64(1) << (2 * width)) - UInt64(1))
        fast_percolates(2, width, mask, neighbors) || continue
        grid = bitmask_to_grid(2, width, mask)
        node = RectangleMergeNode((1, 2, 1, width), findall(==("X"), grid), (0, 0))
        anchor = two_row_seed_anchor(node)
        @test abs(anchor.seeds[1][2] - anchor.seeds[2][2]) <= 1
        @test anchor.seeds[1][1] != anchor.seeds[2][1]
        anchor_grid = fill(".", 2, anchor.bounds[4] - anchor.bounds[3] + 1)
        for cell in anchor.seeds
            anchor_grid[cell[1], cell[2] - anchor.bounds[3] + 1] = "X"
        end
        @test percolates(anchor_grid)
        fast_is_minimal_percolating(2, width, mask, neighbors) && push!(minimal, grid)
    end
    checked = 0
    for first in minimal, second in minimal, shift in 0:2
        grid = fill(".", 5, width + shift)
        grid[1:2, 1:width] .= first
        grid[4:5, (1 + shift):(width + shift)] .= second
        left = RectangleMergeNode((1, 2, 1, width), findall(==("X"), grid[1:2, :]), (0, 0))
        right_seeds = [CartesianIndex(cell[1] + 3, cell[2]) for cell in findall(==("X"), grid[4:5, :])]
        right = RectangleMergeNode((4, 5, 1 + shift, width + shift), right_seeds, (0, 0))
        mixed = sort!(collect(intersect(Set(cell[2] for cell in left.seeds), Set(cell[2] for cell in right.seeds))))
        split = (left = left, right = right, mixed_columns = mixed)
        @test percolates(grid)
        for decomposition in (split, (left = right, right = left, mixed_columns = mixed))
            removed = separated_two_row_redundant_seed(decomposition)
            removed === nothing && continue
            smaller = copy(grid)
            smaller[removed] = "."
            @test percolates(smaller)
            checked += 1
        end
        if is_minimal_percolating(grid)
            @test length(mixed) <= 2
            @test count(cell -> right.bounds[3] <= cell[2] <= right.bounds[4], left.seeds) <= 2
            @test count(cell -> left.bounds[3] <= cell[2] <= left.bounds[4], right.seeds) <= 2
        end
    end
    @test checked > 0
    @test_throws ArgumentError two_row_seed_anchor(RectangleMergeNode((1, 1, 1, 1), [CartesianIndex(1, 1)], (0, 0)))
end

@testset "Height-Five Exhaustive Small-Grid Proof Cases" begin
    cases = Set{String}()
    for width in 1:4
        neighbors = neighbor_masks(5, width)
        for mask in UInt64(0):((UInt64(1) << (5 * width)) - UInt64(1))
            fast_is_minimal_percolating(5, width, mask, neighbors) || continue
            grid = bitmask_to_grid(5, width, mask)
            result = height5_crowding_case(grid; check_minimal = false)
            push!(cases, result.case)
            @test result.crowded <= result.bound <= 8
            if result.case == "separated_two_row_children"
                @test length(result.split.mixed_columns) <= 2
                @test separated_two_row_redundant_seed(result.split) === nothing
            end
        end
    end
    @test "no_mixed_column" in cases
    @test "separated_two_row_children" in cases
end

@testset "Sharp Height-Five Crowding and the Known Height-Eight Family" begin
    report = TOML.parsefile(joinpath(@__DIR__, "..", "experiments", "results", "height5_crowding.toml"))
    columns = height5_sharp_columns()
    @test columns == report["seed_columns"]
    @test length(columns) == report["width"] == 35
    @test sum(count_ones, columns) == report["seed_count"] == 26
    @test count(column -> count_ones(column) >= 2, columns) == report["crowded_columns"] == 8
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:5, column in columns]
    original = copy(grid)
    @test is_minimal_percolating(grid)
    @test grid == original
    result = height5_crowding_case(grid)
    @test result.case == "no_mixed_column"
    @test all(child -> rectangle_height(child.bounds) == 4, (result.split.left, result.split.right))
    @test all(child -> rectangle_seed_crowded_count(child.seeds) == 4, (result.split.left, result.split.right))
    @test result.split.left.bounds[4] < result.split.right.bounds[3] || result.split.right.bounds[4] < result.split.left.bounds[3]
    covered = Set{CartesianIndex{2}}()
    for deletion in report["deletions"]
        cell = CartesianIndex(deletion["row"], deletion["column"])
        @test verify_deletion_fort_columns(grid, cell, deletion["fort_columns"])
        @test !(cell in covered)
        push!(covered, cell)
    end
    @test covered == Set(findall(==("X"), grid))
    @test_throws ArgumentError height5_crowding_case(fill("X", 4, 4))
    @test_throws ArgumentError height5_crowding_case(fill("X", 5, 4))
    for k in 1:6
        known = morris_height8_columns(k)
        @test length(known) == 3 * k + 2
        @test sum(count_ones, known) == 4 * k + 4
        @test count(column -> count_ones(column) >= 2, known) == k + 2
        known_grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:8, column in known]
        @test is_minimal_percolating(known_grid)
    end
    @test_throws ArgumentError morris_height8_columns(0)
end
