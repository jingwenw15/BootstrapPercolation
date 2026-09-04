using Test 

include("../src/simulation.jl")

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