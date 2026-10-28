include("../experiments/height6_crowding.jl")
if !@isdefined(fast_is_minimal_percolating)
    include("../experiments/fast_exact.jl")
end

function height6_pair(first, second, width, shift)
    cols = width + shift
    mask = UInt64(0)
    for row in 1:3, col in 1:width
        bit = UInt64(1) << bit_index(3, width, row, col)
        (first & bit) != 0 && (mask |= UInt64(1) << bit_index(6, cols, row, col))
        (second & bit) != 0 && (mask |= UInt64(1) << bit_index(6, cols, row + 3, col + shift))
    end
    return mask
end

@testset "Three-Row Overlap Nuclei" begin
    neighbors = neighbor_masks(3, 4)
    kinds = Set{String}()
    other = RectangleMergeNode((4, 6, 1, 4), CartesianIndex{2}[], (0, 0))
    for mask in UInt64(0):((UInt64(1) << 12) - UInt64(1))
        fast_percolates(3, 4, mask, neighbors) || continue
        grid = bitmask_to_grid(3, 4, mask)
        node = RectangleMergeNode((1, 3, 1, 4), findall(==("X"), grid), (0, 0))
        nucleus = three_row_overlap_nucleus(node, other)
        push!(kinds, nucleus.case)
        @test all(cell -> cell in node.seeds, nucleus.node.seeds)
        @test rectangle_height(nucleus.node.bounds) == 3
        @test percolates(rectangle_node_grid(nucleus.node))
    end
    @test kinds == Set(("far_two_row_child", "near_two_row_child", "two_one_row_children"))

    width = 5
    neighbors = neighbor_masks(3, width)
    pool = [mask for mask in UInt64(0):((UInt64(1) << 15) - UInt64(1))
            if fast_is_minimal_percolating(3, width, mask, neighbors)]
    indices = unique(round.(Int, range(1, length(pool); length = min(64, length(pool)))))
    samples = pool[indices]
    redundant, minimal = 0, 0
    for shift in 0:4
        cols = width + shift
        neighbors6 = neighbor_masks(6, cols)
        for first in samples, second in samples
            mask = height6_pair(first, second, width, shift)
            @test fast_percolates(6, cols, mask, neighbors6)
            grid = bitmask_to_grid(6, cols, mask)
            top = RectangleMergeNode((1, 3, 1, width), findall(==("X"), grid[1:3, :]), (0, 0))
            bottom = RectangleMergeNode((4, 6, 1 + shift, cols),
                                       [cell + CartesianIndex(3, 0) for cell in findall(==("X"), grid[4:6, :])], (0, 0))
            is_minimal = fast_is_minimal_percolating(6, cols, mask, neighbors6)
            is_minimal && (minimal += 1)
            for (node, other) in ((top, bottom), (bottom, top))
                removed = three_row_overlap_redundant_seed(node, other)
                if removed !== nothing
                    bit = UInt64(1) << bit_index(6, cols, removed[1], removed[2])
                    @test fast_percolates(6, cols, mask & ~bit, neighbors6)
                    @test !is_minimal
                    redundant += 1
                end
                is_minimal || continue
                nucleus = three_row_overlap_nucleus(node, other)
                @test count(cell -> other.bounds[3] <= cell[2] <= other.bounds[4], nucleus.node.seeds) <= nucleus.overlap_seed_bound
                @test count(cell -> other.bounds[3] <= cell[2] <= other.bounds[4], node.seeds) <= 4
                @test removed === nothing
            end
        end
    end
    @test redundant > 0
    @test minimal > 0
end

@testset "Height-Six Small-Grid Proof Cases" begin
    for width in 1:3
        neighbors = neighbor_masks(6, width)
        for mask in UInt64(0):((UInt64(1) << (6 * width)) - UInt64(1))
            fast_is_minimal_percolating(6, width, mask, neighbors) || continue
            grid = bitmask_to_grid(6, width, mask)
            shape = height6_crowding_case(grid; check_minimal = false)
            @test shape.crowded <= shape.bound <= 16
            if shape.case == "adjacent_three_row_children"
                @test length(shape.split.mixed_columns) <= 4
            elseif shape.case == "separated_two_and_three_row_children"
                left, right = shape.split.left, shape.split.right
                pair = rectangle_height(left.bounds) == 2 ? (left = left, right = right) : (left = right, right = left)
                full_pair = (left = pair.left, right = pair.right, mixed_columns = shape.split.mixed_columns)
                @test anchored_strip_redundant_seed(full_pair) === nothing
                @test length(shape.split.mixed_columns) <= 2
            end
        end
    end
end

@testset "Sharp Height-Six Crowding and Known Height-Seven Family" begin
    report = TOML.parsefile(joinpath(@__DIR__, "..", "experiments", "results", "height6_crowding.toml"))
    columns = height6_sharp_columns()
    @test columns == report["seed_columns"]
    @test length(columns) == report["width"] == 75
    @test sum(count_ones, columns) == report["seed_count"] == 54
    @test count(column -> count_ones(column) >= 2, columns) == report["crowded_columns"] == 16
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:6, column in columns]
    original = copy(grid)
    @test is_minimal_percolating(grid)
    @test grid == original
    split = height6_crowding_case(grid).split
    @test all(child -> rectangle_height(child.bounds) == 5, (split.left, split.right))
    @test all(child -> rectangle_seed_crowded_count(child.seeds) == 8, (split.left, split.right))
    @test isempty(split.mixed_columns)
    covered = Set{CartesianIndex{2}}()
    for deletion in report["deletions"]
        cell = CartesianIndex(deletion["row"], deletion["column"])
        @test verify_deletion_fort_columns(grid, cell, deletion["fort_columns"])
        @test !(cell in covered)
        push!(covered, cell)
    end
    @test covered == Set(findall(==("X"), grid))
    for k in 1:12
        known = gottschau_height7_columns(k)
        @test length(known) == 3 * k + 2
        @test sum(count_ones, known) == 4 * k + 4
        @test count(column -> count_ones(column) >= 2, known) == 2 * k
        known_grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:7, column in known]
        @test is_minimal_percolating(known_grid)
    end
    @test_throws ArgumentError gottschau_height7_columns(0)
    @test_throws ArgumentError height6_crowding_case(fill("X", 5, 3))
    @test_throws ArgumentError height6_crowding_case(fill("X", 6, 3))
end
