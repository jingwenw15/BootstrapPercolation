include("../experiments/minimal_extension.jl")

@testset "Morris Minimal-Set Extension" begin
    @testset "One anchored new seed preserves the old closure" begin
        for height in 1:4, cols in 1:3
            height * cols <= 9 || continue
            for mask in UInt64(0):((UInt64(1) << (height * cols)) - UInt64(1))
                grid = bitmask_to_grid(height, cols, mask)
                old_final, _, _, _ = simulate(grid)
                for row in 1:height
                    grid[row, cols] == "X" || continue
                    enlarged = fill(".", height, cols + 1)
                    enlarged[:, 1:cols] .= grid
                    enlarged[row, cols + 1] = "X"
                    enlarged_final, _, _, _ = simulate(enlarged)
                    @test enlarged_final[:, 1:cols] == old_final
                end
            end
        end
    end

    @testset "Exhaustive small rectangles and every boundary seed" begin
        modes = Set{Symbol}()
        for height in 1:4, cols in 1:4
            height * cols <= 12 || continue
            neighbors = neighbor_masks(height, cols)
            for mask in UInt64(0):((UInt64(1) << (height * cols)) - UInt64(1))
                fast_is_minimal_percolating(height, cols, mask, neighbors) || continue
                grid = bitmask_to_grid(height, cols, mask)
                original = copy(grid)
                seed_count = count(==("X"), grid)

                for row in 1:height
                    grid[row, cols] == "X" || continue
                    extension = extend_minimal_percolating(grid; row = row)
                    push!(modes, extension.mode)
                    @test size(extension.grid) == (height, cols + 1)
                    @test count(==("X"), extension.grid) in (seed_count, seed_count + 1)
                    @test is_minimal_percolating(extension.grid)
                    @test grid == original
                end
            end
        end
        @test modes == Set((:move, :add))
    end

    @testset "One-cell boundary and repeated extensions" begin
        grid = fill("X", 1, 1)
        for _ in 1:12
            original = copy(grid)
            next_grid = extend_minimal_percolating(grid).grid
            @test is_minimal_percolating(next_grid)
            @test count(==("X"), next_grid) >= count(==("X"), grid)
            @test grid == original
            grid = next_grid
        end
    end

    @testset "Reject invalid inputs" begin
        @test_throws ArgumentError extend_minimal_percolating(fill(".", 0, 1))
        @test_throws ArgumentError extend_minimal_percolating(fill("?", 1, 1))
        @test_throws ArgumentError extend_minimal_percolating(fill(".", 2, 2))
        @test_throws ArgumentError extend_minimal_percolating(fill("X", 2, 2))
        @test_throws ArgumentError extend_minimal_percolating(fill("X", 1, 1); row = 0)
        @test_throws ArgumentError extend_minimal_percolating(["X" "."; "." "X"]; row = 1)
    end
end
