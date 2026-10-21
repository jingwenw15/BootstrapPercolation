include("../experiments/width4_crowded_columns.jl")
if !@isdefined(fast_is_minimal_percolating)
    include("../experiments/fast_exact.jl")
end

@testset "Graph Component Certificates" begin
    for mask in 0:511
        edges = [(from = i, to = j) for i in 1:3 for j in 1:3
                 if (mask & (1 << (3 * (i - 1) + j - 1))) != 0]
        reached = [i == j for i in 1:3, j in 1:3]
        for edge in edges
            reached[edge.from, edge.to] = true
        end
        for k in 1:3, i in 1:3, j in 1:3
            reached[i, j] |= reached[i, k] && reached[k, j]
        end
        graph = graph_condensation(3, edges)
        for i in 1:3, j in 1:3
            @test (graph.component_of[i] == graph.component_of[j]) == (reached[i, j] && reached[j, i])
        end
        rank = invperm(graph.order)
        @test all(edge -> graph.component_of[edge.from] == graph.component_of[edge.to] ||
                  rank[graph.component_of[edge.from]] < rank[graph.component_of[edge.to]], edges)
    end

    language = (accepting = Bool[false, false, false, true],
                edges = [(from = 1, to = 2), (from = 2, to = 1),
                         (from = 2, to = 3), (from = 3, to = 4), (from = 2, to = 3)])
    starting, values = [1, -1, -1, -1], [0, 0, 1, 1, 1]
    result = bounded_path_statistic(language, starting, values)
    @test result.bound == 3
    path = bounded_statistic_witness(language, starting, values, result.bound)
    @test starting[path.start] + sum(values[path.edges]) == result.bound
    @test language.accepting[language.edges[last(path.edges)].to]
    @test_throws ErrorException bounded_path_statistic(language, starting, [1, 0, 1, 1, 1])
    @test_throws ArgumentError bounded_path_statistic(language, starting, [-1, 0, 1, 1, 1])
    @test_throws ArgumentError bounded_path_statistic(language, starting[1:3], values)
    @test_throws ErrorException bounded_statistic_witness(language, starting, values, 4)
end

@testset "Four Crowded Columns in Every Minimal Set" begin
    audit = Width4SemanticCertificate.load_semantic_certificate()
    result = width4_crowded_column_certificate(audit)
    report = TOML.parsefile(joinpath(@__DIR__, "..", "experiments", "results", "width4_crowded_columns.toml"))
    @test result.bound == report["bound_all_widths_from_1"] == 4
    @test result.graph_bound == report["graph_bound_widths_from_3"]
    @test result.states == report["states"]
    @test result.edges == report["edges"]
    @test result.components == report["strong_components"]
    @test result.crowded_edges == report["crowded_edges"]
    @test result.witness_columns == report["witness_columns"]
    @test verify_bounded_statistic_potential(result.language, result.starting_values,
                                            result.edge_values, result.potential, 4)
    @test !verify_bounded_statistic_potential(result.language, result.starting_values,
                                             result.edge_values, result.potential, 3)
    @test !verify_bounded_statistic_potential(result.language, result.starting_values,
                                             result.edge_values, zeros(Int, result.states), 4)
    changed = copy(result.edge_values)
    changed[1] += 5
    @test !verify_bounded_statistic_potential(result.language, result.starting_values,
                                             changed, result.potential, 4)

    expected_warmup = fill(-1, length(audit.states))
    for encoded in 0:4095
        word = [(encoded >> (4 * col)) & 15 for col in 0:2]
        state = (0, 0, Width4SemanticCertificate.intern!(audit.context, BitSet([0])), ())
        for (i, column) in enumerate(word)
            state = Width4SemanticCertificate.semantic_transition!(audit.context, state, column, i - 1)
            state === nothing && break
        end
        state === nothing && continue
        id = audit.ids[state]
        expected_warmup[id] = max(expected_warmup[id], sum(crowded_column, word))
    end
    @test expected_warmup == result.warmup.crowded

    graph = result.statistic.graph
    for (edge, value) in zip(result.language.edges, result.edge_values)
        if graph.component_of[edge.from] == graph.component_of[edge.to]
            @test value == 0
        end
    end

    # Direct closure/deletion search checks the statistic, not just grid size.
    density = copy(result.starting_values)
    for n in 1:4
        maximum_crowded = -1
        neighbors = neighbor_masks(4, n)
        for mask in UInt64(0):((UInt64(1) << (4 * n)) - UInt64(1))
            fast_is_minimal_percolating(4, n, mask, neighbors) || continue
            crowded = count(col -> count(row -> (mask & (UInt64(1) << bit_index(4, n, row, col))) != 0, 1:4) >= 2, 1:n)
            @test crowded <= result.bound
            maximum_crowded = max(maximum_crowded, crowded)
        end
        if n >= 3
            if n == 4
                following = fill(-1, length(density))
                for (edge, value) in zip(result.language.edges, result.edge_values)
                    density[edge.from] >= 0 || continue
                    following[edge.to] = max(following[edge.to], density[edge.from] + value)
                end
                density = following
            end
            @test maximum_crowded == maximum(density[result.language.accepting])
        end
    end

    word = result.witness_columns
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in word]
    original = copy(grid)
    @test sum(crowded_column, word) == 4
    @test is_minimal_percolating(grid)
    @test grid == original
    for cell in findall(==("X"), grid)
        removed = copy(grid)
        removed[cell] = "."
        @test !percolates(removed)
    end

    family = width4_crowded_pumping_family!(audit, word)
    @test word == result.witness_columns
    @test family.left == report["pumping_family"]["left"]
    @test family.block == report["pumping_family"]["block"]
    @test family.right == report["pumping_family"]["right"]
    @test sum(crowded_column, family.block) == 0
    @test sum(count_ones, family.block) == 2
    state = (0, 0, Width4SemanticCertificate.intern!(audit.context, BitSet([0])), ())
    prefix = vcat(family.left, family.block)
    for (i, column) in enumerate(prefix)
        state = Width4SemanticCertificate.semantic_transition!(audit.context, state, column, min(i - 1, 2))
    end
    loop_state = state
    for column in family.block
        state = Width4SemanticCertificate.semantic_transition!(audit.context, state, column, 2)
    end
    @test state == loop_state
    for copies in 1:5
        extended = vcat(family.left, repeat(family.block, copies), family.right)
        @test length(extended) == family.base_width + 3 * (copies - 1)
        @test sum(crowded_column, extended) == 4
        extended_grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in extended]
        @test is_minimal_percolating(extended_grid)
    end
end
