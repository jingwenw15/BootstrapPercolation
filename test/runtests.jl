using Test 

include("../src/simulation.jl")
include("../src/minimal.jl")
include("../experiments/enumerate.jl")

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


@testset "Minimal Percolation Simulator" begin
    @testset "Is Minimal Percolating" begin 
        grid = [
            "." "X" ".";
            "X" "." "X";
            "." "X" "."
        ]

        is_min_percolating = is_minimal_percolating(grid)

        @test is_min_percolating == true
    end

    @testset "Not Minimal Percolating" begin
        grid = [
            "X" "X" ".";
            "X" "." "X";
            "." "X" "."
        ]

        is_min_percolating = is_minimal_percolating(grid)

        @test is_min_percolating == false
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
    end

    @testset "2x2 grid" begin
        result = enumerate_minimal_percolating(2)

        @test result.total_configurations == 16
        @test result.minimal_percolating_count == 2
        @test result.maximum_size == 2
        @test length(result.maximizers) == 2
        @test all(is_minimal_percolating(grid) for grid in result.maximizers)
        @test all(count_infected(grid) == result.maximum_size for grid in result.maximizers)
    end
end
