include("../experiments/certify_width4_counts.jl")
if !@isdefined(fast_is_minimal_percolating)
    include("../experiments/fast_exact.jl")
end

@testset "Certified Width-Four Maximizer Counts" begin
    audit = Width4SemanticCertificate.load_semantic_certificate()
    language = width4_optimal_language(audit)
    quotient = width4_optimal_count_quotient(language)
    report = TOML.parsefile(joinpath(@__DIR__, "..", "experiments", "results", "width4_count_recurrences.toml"))

    @test length(language.ids) == report["optimal_language_states"]
    @test length(language.edges) == report["optimal_language_edges"]
    @test length(quotient.accepting) == report["counting_quotient_states"]
    @test length(quotient.edges) == report["counting_quotient_edges"]
    @test sum(language.initial_counts) == sum(quotient.initial_counts)
    @test width4_optimal_language_counts(language, 80) == width4_quotient_counts(quotient, 80)
    @test_throws ArgumentError width4_quotient_counts(quotient, 18)

    # Check the quotient's defining identities at every original state, not
    # just agreement of a finite sample of total counts.
    outgoing = [Dict{Int, Int}() for _ in language.ids]
    for edge in language.edges
        block = quotient.blocks[edge.to]
        outgoing[edge.from][block] = get(outgoing[edge.from], block, 0) + 1
    end
    block_outgoing = [Dict{Int, Int}() for _ in quotient.accepting]
    for edge in quotient.edges
        block_outgoing[edge.from][edge.to] = edge.multiplicity
    end
    for id in eachindex(language.ids)
        block = quotient.blocks[id]
        @test outgoing[id] == block_outgoing[block]
        @test language.accepting[id] == quotient.accepting[block]
    end

    # Compare against the older, separately implemented packed-frontier DP.
    counts = Dict(row.cols => row.maximizing_count for row in width4_quotient_counts(quotient, 40))
    for line in readlines(joinpath(@__DIR__, "..", "experiments", "results", "width4_graph_acceptance_4_to_40.csv"))[2:end]
        fields = split(line, ',')
        n, size, ways = parse(Int, fields[1]), parse(Int, fields[2]), parse(BigInt, fields[3])
        if n <= 22
            row = only(filter(row -> row.cols == n, language.prefix))
            @test (row.maximum_size, row.maximizing_count) == (size, ways)
        end
        n >= 19 && @test counts[n] == ways
    end

    # Closure and every single-seed deletion, without frontier states.
    for n in 3:4
        neighbors = neighbor_masks(4, n)
        best, ways = -1, big(0)
        for mask in UInt64(0):((UInt64(1) << (4 * n)) - UInt64(1))
            fast_is_minimal_percolating(4, n, mask, neighbors) || continue
            size = count_ones(mask)
            if size > best
                best, ways = size, big(1)
            elseif size == best
                ways += 1
            end
        end
        row = only(filter(row -> row.cols == n, language.prefix))
        @test (row.maximum_size, row.maximizing_count) == (best, ways)
    end

    common = width4_count_common_polynomial(report["recurrences"])
    @test common == parse.(BigInt, report["common_polynomial"])
    for recurrence in report["recurrences"]
        offset = recurrence["first_width"] - 19
        coefficients = parse.(BigInt, recurrence["coefficients"])
        @test length(coefficients) == recurrence["order"]
        @test quotient_residue_counts(quotient, length(coefficients) - 1; offset = offset) ==
              parse.(BigInt, recurrence["initial_counts"])
        @test certify_count_recurrence(quotient, coefficients; offset = offset)
        changed = copy(coefficients)
        changed[1] += 1
        @test !certify_count_recurrence(quotient, changed; offset = offset)
    end
end

@testset "Linear Count Recurrence Tools" begin
    fibonacci = BigInt[0, 1]
    for _ in 1:30
        push!(fibonacci, fibonacci[end] + fibonacci[end - 1])
    end
    @test count_recurrence_mod(fibonacci, 101) == [1, 1]
    @test isempty(count_recurrence_mod(zeros(Int, 20), 101))
    @test_throws ArgumentError count_recurrence_mod(fibonacci, 2_000_000_000)
    @test count_monic_polynomial_root(BigInt[1, -6, 13, -12, 4], 2) == [1, -3, 2]
    @test_throws ErrorException count_monic_polynomial_root(BigInt[1, 0, 1], 2)

    # A two-state Fibonacci representation exercises the proof checker itself.
    model = (initial_counts = BigInt[1, 0], accepting = Bool[true, false],
             edges = [(from = 1, to = 1, multiplicity = 1),
                      (from = 1, to = 2, multiplicity = 1),
                      (from = 2, to = 1, multiplicity = 1)])
    @test quotient_residue_counts(model, 4) == [1, 3, 13, 55, 233]
    @test propose_count_recurrence(model; fit_steps = 20) == [4, 1]
    @test certify_count_recurrence(model, BigInt[4, 1])
    @test !certify_count_recurrence(model, BigInt[3, 1])
    @test_throws ArgumentError certify_count_recurrence(model, BigInt[])
    @test_throws ArgumentError quotient_residue_counts(model, 2; offset = 3)
end
