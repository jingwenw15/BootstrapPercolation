using Test 
include("semilinear_growth.jl")

include("../src/simulation.jl")
include("../src/minimal.jl")
include("../experiments/enumerate.jl")
include("../experiments/symmetry.jl")
include("../experiments/search_exact.jl")
include("../experiments/two_row_construction.jl")
include("../experiments/fast_exact.jl")
include("../experiments/fixed_width_state_model.jl")
include("../experiments/extend_width4.jl")
include("../experiments/width4_transfer.jl")
include("../experiments/width4_stable_sets.jl")
include("../experiments/width4_minimality_dp.jl")
include("../experiments/width4_graph_acceptance.jl")
include("../experiments/width4_eventual_periodicity.jl")
include("../experiments/width4_boundary_recurrence.jl")
include("../experiments/width4_formula_constructions.jl")
include("../experiments/check_width4_boundary_certificate.jl")
include("minimal_extension.jl")
include("width4_semantic_certificate.jl")
include("paper_constructions.jl")
include("width4_optimal_counts.jl")
include("width4_crowded_columns.jl")
include("rectangle_merge_proof.jl")

@testset "Generic Fixed-Width State Model" begin
    @testset "Every small word matches direct bootstrap closure" begin
        for (height, cols) in ((1, 4), (2, 4), (3, 4))
            neighbors = neighbor_masks(height, cols)
            total = height * cols

            for mask in UInt64(0):((UInt64(1) << total) - UInt64(1))
                columns = fixed_width_columns_from_mask(height, cols, mask)
                @test fixed_width_word_is_accepted(height, columns) ==
                      fast_is_minimal_percolating(height, cols, mask, neighbors)
            end
        end
    end

    @testset "Merged counts and extrema match exhaustive search" begin
        for (height, cols) in ((1, 4), (2, 4), (3, 4))
            reference = fixed_width_reference_value(height, cols)
            brute = fixed_width_brute_summary(height, cols)

            @test reference.maximum_size == brute.maximum_size
            @test reference.maximizing_count == brute.maximizing_count
            @test reference.minimal_count == brute.minimal_count
        end
    end
end

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

@testset "Width-Four Column Transfer Search" begin
    @testset "Column local viability matches generated search" begin
        for (cols, size) in [(4, 5), (5, 6), (8, 8)]
            generated = fast_find_minimal_percolating_sets_of_size_generated_canonical(4, cols, size; store = false)
            transfer = width4_transfer_find_minimal_percolating(cols, size; store = false)

            @test width4_locally_viable_count(cols, size) == generated.generated
            @test transfer.generated == generated.generated
            @test transfer.checked == generated.checked_representatives
            @test transfer.raw_maximizers == generated.raw_maximizers
            @test transfer.symmetry_classes == generated.symmetry_classes
        end
    end
end

@testset "Width-Four Stable Set Characterization" begin
    @testset "Stable-set predicates match simulator on 4 x 4" begin
        neighbors = neighbor_masks(4, 4)

        for x in UInt64(0):(UInt64(1) << 16) - UInt64(1)
            tuple_summary = width4_stable_witness_summary(4, x)
            bit_summary = width4_stable_witness_summary_bits(4, x)

            @test tuple_summary.has_zero_seed_obstruction == bit_summary.has_zero_seed_obstruction
            @test tuple_summary.witnessed_seeds == bit_summary.witnessed_seeds
            @test width4_percolates_by_stable_sets(4, x) == fast_percolates(4, 4, x, neighbors)
            @test width4_is_minimal_percolating_by_stable_sets(4, x) == fast_is_minimal_percolating(4, 4, x, neighbors)
            @test width4_is_minimal_percolating_by_witness_summary(4, x) == fast_is_minimal_percolating(4, 4, x, neighbors)
        end
    end

    @testset "Stable-set predicates certify known width-four examples" begin
        example_4x10 = bitmask_from_positions(4, 10, [1, 2, 8, 9, 14, 15, 29, 30, 35, 36])

        @test width4_is_minimal_percolating_by_stable_sets(10, example_4x10)
        @test width4_is_minimal_percolating_by_witness_summary(10, example_4x10)
        @test fast_is_minimal_percolating(4, 10, example_4x10)
    end

    @testset "Stable automaton counts locally viable percolating sets" begin
        for (cols, size) in [(4, 5), (5, 6), (8, 8)]
            neighbors = neighbor_masks(4, cols)
            direct_count = 0

            foreach_width4_locally_viable_sequence(cols, size) do mask
                if fast_percolates(4, cols, mask, neighbors)
                    direct_count += 1
                end
            end

            @test width4_locally_viable_percolating_count(cols, size) == direct_count
        end
    end

    @testset "Stable-witness search matches simulator search" begin
        for (cols, size) in [(4, 5), (5, 6), (8, 8)]
            simulator = width4_transfer_find_minimal_percolating(cols, size; store = false)
            stable = width4_find_minimal_by_stable_witnesses(cols, size; store = false)

            @test stable.generated == simulator.generated
            @test stable.checked == simulator.checked
            @test stable.raw_maximizers == simulator.raw_maximizers
            @test stable.symmetry_classes == simulator.symmetry_classes
        end
    end

    @testset "Witness-pruned search matches simulator search" begin
        for (cols, size) in [(4, 5), (5, 6)]
            simulator = width4_transfer_find_minimal_percolating(cols, size; store = false)
            pruned = width4_find_minimal_by_witness_pruning(cols, size; store = false)

            @test pruned.raw_maximizers == simulator.raw_maximizers
            @test pruned.symmetry_classes == simulator.symmetry_classes
            @test pruned.generated_minimal == simulator.raw_maximizers
        end
    end

    @testset "Merged-state DP matches simulator search" begin
        for (cols, size) in [(4, 5), (5, 6)]
            simulator = width4_transfer_find_minimal_percolating(cols, size; store = false, canonical = false)
            merged = width4_count_minimal_by_merged_state(cols, size)

            @test merged.raw_minimal_percolating == simulator.raw_maximizers
        end
    end

    @testset "Graph acceptance matches merged-state exact values" begin
        expected = Dict(
            4 => (maximum_size = 5, raw = 360),
            5 => (maximum_size = 6, raw = 280),
            6 => (maximum_size = 7, raw = 40),
        )

        for (cols, values) in sort(collect(expected))
            result = width4_graph_acceptance_value(cols)

            @test result.maximum_size == values.maximum_size
            @test result.raw_maximizers == values.raw
        end

        rows = width4_graph_acceptance_sequence(10; first_col = 4)
        @test [(row.maximum_size, row.raw_maximizers) for row in rows] == [
            (5, 360),
            (6, 280),
            (7, 40),
            (8, 2),
            (8, 7074),
            (9, 1312),
            (10, 82),
        ]

        report = width4_recurrence_report(rows)
        @test report.earliest_start == 5
        @test report.verified_comparisons == 3
        @test isempty([row for row in rows if row.cols >= 5 && row.maximum_size != width4_formula(row.cols)])

        certificate = width4_boundary_recurrence_certificate()
        @test certificate.recurrence_start == 19
        @test certificate.recurrence_end == 22
        @test certificate.period == 3
        @test certificate.gain == 2
        @test all(certificate.values[n] == width4_formula(n) for n in 5:certificate.recurrence_end)

        for cols in 9:15
            construction = width4_formula_construction(cols)
            @test construction.size == width4_formula(cols)
            @test construction.verified_minimal_percolating
        end

        construction_certificate = width4_formula_construction_certificate()
        @test construction_certificate.block_length == 3
        @test construction_certificate.block_weight == 2
        @test all(loop.returns_to_same_state for loop in construction_certificate.loops)
        @test all(loop.suffix_accepts for loop in construction_certificate.loops)
        @test all(loop.base_is_minimal_percolating for loop in construction_certificate.loops)

        independent = check_width4_boundary_certificate()
        @test independent.verified
        @test independent.core_states == 15150
        @test independent.core_edges == 46618
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
