using Test 

include("../src/simulation.jl")
include("../src/minimal.jl")
include("../experiments/enumerate.jl")
include("../experiments/symmetry.jl")
include("../experiments/search_exact.jl")

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
