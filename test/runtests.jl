using Test 

include("../src/simulation.jl")
include("../src/minimal.jl")
include("../experiments/enumerate.jl")
include("../experiments/symmetry.jl")
include("../experiments/search_exact.jl")
include("../experiments/two_row_construction.jl")
include("../experiments/fast_exact.jl")
include("../experiments/extend_width4.jl")

@testset "Bootstrap Percolation Simulator" begin 

    @testset "Already fully infected" begin 
        grid = [
            "X" "X";
            "X" "X"
        ]

        finalGrid, percolated, time, _ = simulate(grid)

        @test percolated == true
        @test time == 0 
        @test all(finalGrid .== "X")
    end 

    @testset "No spread" begin 
        grid = [
            "X" "." ".";
            "." "." ".";
            "." "." "X" 
        ]

        finalGrid, percolated, time, _ = simulate(grid) 

        @test percolated == false
        @test time == 0 
        @test finalGrid == grid 
    end 

    @testset "Center becomes infected" begin 
        grid = [
            "." "X" "."; 
            "X" "." ".";
            "." "." "."
        ]

        finalGrid, percolated, time, _ = simulate(grid)

        expected = [
            "X" "X" ".";
            "X" "X" ".";
            "." "." "."
        ]

        @test finalGrid == expected
        @test percolated == false
        @test time == 1
    end 

    @testset "Percolates" begin
        grid = [
            "." "X" ".";
            "X" "." "X";
            "." "X" "."
        ]

        finalGrid, percolated, time, _ = simulate(grid)

        @test percolated == true
        @test all(finalGrid .== "X")
        @test time == 1
    end

    @testset "History length matches time" begin
        grid = [
            "X" "X" ".";
            "X" "." ".";
            "." "." "."
        ]

        _, _, time, history = simulate(grid)

        @test length(history) == time + 1
    end

    @testset "Synchronous timing with two rounds" begin
        grid = [
            "." "." "X";
            "." "X" ".";
            "X" "." "."
        ]

        finalGrid, percolated, time, history = simulate(grid)

        expected_t1 = [
            "." "X" "X";
            "X" "X" "X";
            "X" "X" "."
        ]

        @test percolated == true
        @test time == 2
        @test length(history) == 3
        @test history[2] == expected_t1
        @test all(finalGrid .== "X")
    end
    
end

@testset "Fast Bitmask Exact Search" begin
    @testset "Bitmask grid conversion" begin
        mask = bitmask_from_positions(2, 3, [1, 3, 5])

        @test bitmask_to_grid(2, 3, mask) == [
            "X" "." "X";
            "." "X" "."
        ]
    end

    @testset "Fast predicates match grid predicates" begin
        for rows in 2:4, cols in rows:5
            neighbors = neighbor_masks(rows, cols)
            total = rows * cols

            for x in 0:min(2^total - 1, 255)
                mask = UInt64(x)
                grid = bitmask_to_grid(rows, cols, mask)

                @test fast_percolates(rows, cols, mask, neighbors) == percolates(grid)
                @test fast_is_minimal_percolating(rows, cols, mask, neighbors) == is_minimal_percolating(grid)
            end
        end
    end

    @testset "Fast exact search matches exact baseline" begin
        for (rows, cols) in [(2, 5), (3, 4), (4, 4), (4, 5)]
            baseline = exact_search_summary(rows, cols; upper_size = morris_upper_bound_size(rows, cols))
            fast = fast_exact_search_descending(rows, cols; upper_size = morris_upper_bound_size(rows, cols), store = false)

            @test fast.certified == baseline.certified
            @test fast.maximum_size == baseline.maximum_size
            @test fast.raw_maximizers == baseline.raw_maximizers
            @test fast.total_checked == baseline.total_checked
        end
    end

    @testset "Local forced-seed filter is a valid necessary condition" begin
        neighbors = neighbor_masks(3, 3)
        locally_forced = bitmask_from_positions(3, 3, [2, 4, 5])
        not_locally_forced = bitmask_from_positions(3, 3, [1, 3, 7])

        @test has_locally_forced_seed(locally_forced, neighbors)
        @test !has_locally_forced_seed(not_locally_forced, neighbors)
    end

    @testset "Filtered fast exact search matches unfiltered search" begin
        for (rows, cols) in [(3, 4), (4, 4), (4, 5)]
            upper = morris_upper_bound_size(rows, cols)
            unfiltered = fast_exact_search_descending(rows, cols; upper_size = upper, store = false)
            filtered = fast_exact_search_descending_filtered(rows, cols; upper_size = upper, store = false)

            @test filtered.certified == unfiltered.certified
            @test filtered.maximum_size == unfiltered.maximum_size
            @test filtered.raw_maximizers == unfiltered.raw_maximizers
            @test filtered.total_checked <= filtered.total_candidates
            @test filtered.total_candidates == unfiltered.total_checked
        end
    end

    @testset "Generated fast exact search matches filtered search" begin
        for (rows, cols) in [(3, 4), (4, 4), (4, 5)]
            upper = morris_upper_bound_size(rows, cols)
            filtered = fast_exact_search_descending_filtered(rows, cols; upper_size = upper, store = false)
            generated = fast_exact_search_descending_generated(rows, cols; upper_size = upper, store = false)

            @test generated.certified == filtered.certified
            @test generated.maximum_size == filtered.maximum_size
            @test generated.raw_maximizers == filtered.raw_maximizers
            @test generated.total_generated == filtered.total_checked
        end
    end

    @testset "Symmetry-generated search matches generated search" begin
        for (rows, cols) in [(3, 4), (4, 4), (4, 5)]
            upper = morris_upper_bound_size(rows, cols)
            generated = fast_exact_search_descending_generated(rows, cols; upper_size = upper, store = false)
            canonical = fast_exact_search_descending_generated_canonical(rows, cols; upper_size = upper, store = false)

            @test canonical.certified == generated.certified
            @test canonical.maximum_size == generated.maximum_size
            @test canonical.raw_maximizers == generated.raw_maximizers
            @test canonical.total_checked_representatives <= canonical.total_generated
        end
    end
end

@testset "Width-Four Extension Search" begin
    @testset "Blank column insertion preserves row-major seeds" begin
        mask = bitmask_from_positions(4, 3, [1, 6, 12])
        inserted = insert_empty_column_mask(4, 3, mask, 2)

        @test bitmask_to_grid(4, 4, inserted) == [
            "X" "." "." ".";
            "." "." "." "X";
            "." "." "." ".";
            "." "." "." "X"
        ]
    end
end

@testset "Two-Row Extremal Construction" begin
    @testset "Column-word construction" begin
        @test grid_from_column_words(["01", "10"]) == [
            "." "X";
            "X" "."
        ]
    end

    @testset "Construction matches Morris upper bound and is minimal" begin
        for n in 2:30
            grid = two_row_extremal_construction(n)

            @test size(grid) == (2, n)
            @test count_infected(grid) == morris_upper_bound_size(2, n)
            @test is_minimal_percolating(grid)
        end
    end

    @testset "Construction matches exact search for computed range" begin
        for n in 2:12
            result = exact_search_summary(2, n; upper_size = morris_upper_bound_size(2, n))

            @test result.certified
            @test count_infected(two_row_extremal_construction(n)) == result.maximum_size
        end
    end
end

@testset "Size-Ordered Exact Search" begin
    @testset "Grid generation from positions matches row-major convention" begin
        @test grid_from_positions(2, [1, 4]) == [
            "X" ".";
            "." "X"
        ]

        @test grid_from_positions(2, [2, 3]) == [
            "." "X";
            "X" "."
        ]

        @test grid_from_positions(2, 3, [1, 3, 5]) == [
            "X" "." "X";
            "." "X" "."
        ]
    end

    @testset "Descending search matches exhaustive baseline" begin
        for n in 2:4
            baseline = enumerate_minimal_percolating(n)
            result = exact_search_descending(n; upper_size = n * n)

            @test result.certified
            @test result.maximum_size == baseline.maximum_size
            @test length(result.maximizers) == length(baseline.maximizers)
            @test Set(grid_key.(result.maximizers)) == Set(grid_key.(baseline.maximizers))
        end
    end

    @testset "Rectangle search is transpose invariant for small grids" begin
        for (rows, cols) in [(2, 3), (2, 4), (3, 4)]
            result = exact_search_descending(rows, cols; upper_size = morris_upper_bound_size(rows, cols))
            transposed = exact_search_descending(cols, rows; upper_size = morris_upper_bound_size(cols, rows))

            @test result.certified
            @test transposed.certified
            @test result.maximum_size == transposed.maximum_size
            @test length(result.maximizers) == length(transposed.maximizers)
        end
    end

    @testset "Summary search matches stored exact search" begin
        for (rows, cols) in [(2, 5), (3, 4), (4, 4)]
            full = exact_search_descending(rows, cols; upper_size = morris_upper_bound_size(rows, cols))
            summary = exact_search_summary(rows, cols; upper_size = morris_upper_bound_size(rows, cols))

            @test summary.certified == full.certified
            @test summary.maximum_size == full.maximum_size
            @test summary.raw_maximizers == length(full.maximizers)
            @test summary.total_checked == full.total_checked
        end
    end
end

@testset "Symmetry Reduction" begin
    @testset "Eight symmetries preserve square shape and entries" begin
        grid = [
            "a" "b" "c";
            "d" "e" "f";
            "g" "h" "i"
        ]

        symmetries = square_symmetries(grid)

        @test length(symmetries) == 8
        @test all(size(symmetry) == (3, 3) for symmetry in symmetries)
        @test length(Set(grid_key(symmetry) for symmetry in symmetries)) == 8
        @test all(sort(vec(symmetry)) == sort(vec(grid)) for symmetry in symmetries)
    end

    @testset "Canonical key is invariant under square symmetries" begin
        grid = [
            "." "X" "X";
            "X" "." ".";
            "X" "." "."
        ]

        key = canonical_key(grid)

        @test all(canonical_key(symmetry) == key for symmetry in square_symmetries(grid))
    end

    @testset "Symmetry classes cover all reported maximizers" begin
        for n in 2:4
            result = enumerate_minimal_percolating(n)
            classes = symmetry_classes(result.maximizers)

            @test sum(length(grids) for grids in values(classes)) == length(result.maximizers)
            @test all(!isempty(grids) for grids in values(classes))
            @test all(is_minimal_percolating(grid) for grids in values(classes) for grid in grids)
        end
    end

    @testset "Exact symmetry-class counts for current baseline" begin
        expected_classes = Dict(2 => 1, 3 => 3, 4 => 48)

        for n in 2:4
            report = symmetry_class_report(n)

            @test report.symmetry_classes == expected_classes[n]
            @test sum(report.class_sizes) == report.raw_maximizers
        end
    end
end


@testset "Minimal Percolation Simulator" begin
    @testset "Is Minimal Percolating" begin 
        grid = [
            "." "X" ".";
            "X" "." "X";
            "." "X" "."
        ]

        is_min_percolating = is_minimal_percolating(grid)

        @test is_min_percolating == true
        @test verifies_minimal_by_single_removal(grid)
    end

    @testset "Not Minimal Percolating" begin
        grid = [
            "X" "X" ".";
            "X" "." "X";
            "." "X" "."
        ]

        is_min_percolating = is_minimal_percolating(grid)

        @test is_min_percolating == false
        @test !verifies_minimal_by_single_removal(grid)
    end

    @testset "Not Percolating" begin
        grid = [
            "." "X" ".";
            "X" "." ".";
            "." "X" "."
        ]

        is_min_percolating = is_minimal_percolating(grid)

        @test is_min_percolating == false
    end
end

@testset "Configuration Generation" begin
    @testset "Specific bit positions" begin
        @test configuration(2, 0) == [
            "." ".";
            "." "."
        ]

        @test configuration(2, 1) == [
            "X" ".";
            "." "."
        ]

        @test configuration(2, 2) == [
            "." "X";
            "." "."
        ]

        @test configuration(2, 4) == [
            "." ".";
            "X" "."
        ]

        @test configuration(2, 8) == [
            "." ".";
            "." "X"
        ]
    end

    @testset "All 2x2 configurations appear once" begin
        generated = Set(join(vec(configuration(2, x)), "") for x in 0:15)

        @test length(generated) == 16
        @test all(join(vec(configuration(2, x)), "") in generated for x in 0:15)
    end
end

@testset "Exhaustive Enumeration" begin
    @testset "1x1 grid" begin
        result = enumerate_minimal_percolating(1)

        @test result.total_configurations == 2
        @test result.minimal_percolating_count == 1
        @test result.maximum_size == 1
        @test result.maximizers == [[
            "X"
        ;;]]
        @test isempty(verify_reported_maximizers(result))
    end

    @testset "2x2 grid" begin
        result = enumerate_minimal_percolating(2)

        @test result.total_configurations == 16
        @test result.minimal_percolating_count == 2
        @test result.maximum_size == 2
        @test length(result.maximizers) == 2
        @test all(is_minimal_percolating(grid) for grid in result.maximizers)
        @test all(count_infected(grid) == result.maximum_size for grid in result.maximizers)
        @test isempty(verify_reported_maximizers(result))
    end

    @testset "Reported maximizers pass single-removal verification through n=4" begin
        for n in 2:4
            result = enumerate_minimal_percolating(n)

            @test isempty(verify_reported_maximizers(result))
        end
    end
end
