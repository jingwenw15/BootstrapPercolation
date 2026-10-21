using TOML
if !@isdefined(Width4SemanticCertificate)
    include("check_width4_semantic_certificate.jl")
end
if !@isdefined(graph_condensation)
    include("graph_components.jl")
end
if !@isdefined(is_minimal_percolating)
    include("../src/minimal.jl")
end

crowded_column(column) = Int(count_ones(column) >= 2)

function width4_crowded_warmup!(audit)
    checker = Width4SemanticCertificate
    initial = (0, 0, checker.intern!(audit.context, BitSet([0])), ())
    current = Dict(initial => (0, Int[]))
    for phase in 0:2
        next = Dict{checker.SemanticState, Tuple{Int, Vector{Int}}}()
        for (state, (crowded, word)) in current, column in 0:15
            target = checker.semantic_transition!(audit.context, state, column, phase)
            target === nothing && continue
            candidate = crowded + crowded_column(column)
            candidate_word = vcat(word, column)
            old = get(next, target, (-1, Int[]))
            if candidate > old[1] || (candidate == old[1] && Tuple(candidate_word) < Tuple(old[2]))
                next[target] = (candidate, candidate_word)
            end
        end
        current = next
    end
    size = length(audit.states)
    crowded = fill(-1, size)
    words = Dict{Int, Vector{Int}}()
    for (state, (density, word)) in current
        id = audit.ids[state]
        crowded[id], words[id] = density, word
    end
    starts = audit.initial_scores .!= checker.CERTIFICATE_NEGATIVE_INFINITY
    (crowded .>= 0) == starts || error("crowded-column warm-up state set disagrees")
    return (crowded = crowded, words = words)
end

"""Bound a nonnegative edge statistic when every within-SCC edge has weight zero."""
function bounded_path_statistic(language, starting_values, edge_values)
    length(starting_values) == length(language.accepting) || throw(ArgumentError("invalid starting values"))
    length(edge_values) == length(language.edges) || throw(ArgumentError("invalid edge values"))
    all(>=(0), edge_values) || throw(ArgumentError("edge values must be nonnegative"))
    graph = graph_condensation(length(language.accepting), language.edges)
    for (edge, value) in zip(language.edges, edge_values)
        if graph.component_of[edge.from] == graph.component_of[edge.to] && value != 0
            error("positive-weight edge belongs to a cycle; no finite bound certified")
        end
    end
    maxima = fill(-1, length(graph.components))
    for id in eachindex(starting_values)
        component = graph.component_of[id]
        maxima[component] = max(maxima[component], starting_values[id])
    end
    for component in graph.order
        maxima[component] >= 0 || continue
        for id in graph.outgoing[component]
            target = graph.component_of[language.edges[id].to]
            maxima[target] = max(maxima[target], maxima[component] + edge_values[id])
        end
    end
    bound = maximum(maxima[graph.component_of[id]] for id in eachindex(language.accepting) if language.accepting[id])
    bound >= 0 || error("no accepting path")
    return (bound = bound, graph = graph, component_maxima = maxima)
end

function bounded_statistic_witness(language, starting_values, edge_values, bound)
    size = length(language.accepting)
    outgoing = [Int[] for _ in 1:size]
    for (id, edge) in enumerate(language.edges)
        push!(outgoing[edge.from], id)
    end
    parent = fill(-1, size * (bound + 1))
    parent_edge = zeros(Int, length(parent))
    queue = Int[]
    for id in 1:size
        0 <= starting_values[id] <= bound || continue
        index = starting_values[id] * size + id
        parent[index] = 0
        push!(queue, index)
    end
    cursor = 1
    while cursor <= length(queue)
        index = queue[cursor]
        value, vertex = div(index - 1, size), mod(index - 1, size) + 1
        if value == bound && language.accepting[vertex]
            edge_ids = Int[]
            while parent[index] != 0
                push!(edge_ids, parent_edge[index])
                index = parent[index]
            end
            return (start = mod(index - 1, size) + 1, edges = reverse(edge_ids))
        end
        for id in outgoing[vertex]
            edge = language.edges[id]
            next_value = value + edge_values[id]
            next_value <= bound || continue
            target = next_value * size + edge.to
            parent[target] == -1 || continue
            parent[target], parent_edge[target] = index, id
            push!(queue, target)
        end
        cursor += 1
    end
    error("the claimed bound has no witness")
end

function verify_bounded_statistic_potential(language, starting_values, edge_values, potential, bound)
    length(potential) == length(language.accepting) == length(starting_values) ||
        throw(ArgumentError("invalid potential dimensions"))
    length(edge_values) == length(language.edges) || throw(ArgumentError("invalid edge values"))
    all(value -> value isa Integer && 0 <= value <= bound, potential) || return false
    all(id -> starting_values[id] < 0 || starting_values[id] <= potential[id], eachindex(potential)) || return false
    for (edge, value) in zip(language.edges, edge_values)
        potential[edge.from] + value <= potential[edge.to] || return false
    end
    return all(id -> !language.accepting[id] || potential[id] <= bound, eachindex(potential))
end

function width4_crowded_column_certificate(audit; verify = true)
    checker = Width4SemanticCertificate
    verify && checker.verify_loaded_semantic_certificate!(audit)
    warmup = width4_crowded_warmup!(audit)
    size = length(audit.states)
    core = checker.reverse_reachable_vertices(size, audit.edges, audit.accepting)
    ids = findall(core)
    compact = zeros(Int, size)
    compact[ids] .= eachindex(ids)
    edges = NamedTuple{(:from, :to, :column), Tuple{Int, Int, Int}}[]
    for source in ids, column in 0:15
        target = audit.targets[source, column + 1]
        target != 0 && core[target] || continue
        push!(edges, (from = compact[source], to = compact[target], column = column))
    end
    language = (ids = ids, accepting = audit.accepting[ids], edges = edges)
    starting = warmup.crowded[ids]
    values = [crowded_column(edge.column) for edge in language.edges]
    result = bounded_path_statistic(language, starting, values)
    potential = result.component_maxima[result.graph.component_of]
    verify_bounded_statistic_potential(language, starting, values, potential, result.bound) ||
        error("direct edge-by-edge potential verification failed")
    path = bounded_statistic_witness(language, starting, values, result.bound)
    word = vcat(warmup.words[ids[path.start]],
                [language.edges[id].column for id in path.edges])
    sum(crowded_column, word) == result.bound || error("witness has the wrong crowded-column count")
    return (bound = max(2, result.bound), graph_bound = result.bound, witness_columns = word,
            components = length(result.graph.components), states = length(language.ids),
            edges = length(language.edges), crowded_edges = count(>(0), values),
            language = language, warmup = warmup, statistic = result,
            starting_values = starting, edge_values = values, potential = potential)
end

function width4_crowded_pumping_family!(audit, word)
    checker = Width4SemanticCertificate
    state = (0, 0, checker.intern!(audit.context, BitSet([0])), ())
    function follow(id, columns)
        for column in columns
            id = audit.targets[id, column + 1]
            id == 0 && return 0
        end
        return id
    end
    for i in eachindex(word)
        state = checker.semantic_transition!(audit.context, state, word[i], min(i - 1, 2))
        state === nothing && error("the pumping input has a rejected prefix")
        i >= 3 || continue
        id = audit.ids[state]
        for x in (0, 1, 2, 4, 8), y in (0, 1, 2, 4, 8), z in (0, 1, 2, 4, 8)
            block = [x, y, z]
            sum(count_ones, block) == 2 || continue
            repeated = follow(id, block)
            repeated != 0 && follow(repeated, block) == repeated || continue
            terminal = follow(repeated, word[i+1:end])
            terminal != 0 && audit.accepting[terminal] || continue
            return (left = word[1:i], block = block, right = word[i+1:end],
                    minimum_copies = 1, base_width = length(word) + length(block))
        end
    end
    error("no three-column pumping family found")
end

function write_width4_crowded_certificate(path = joinpath(@__DIR__, "results", "width4_crowded_columns.toml"))
    audit = Width4SemanticCertificate.load_semantic_certificate()
    result = width4_crowded_column_certificate(audit)
    grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in result.witness_columns]
    is_minimal_percolating(grid) || error("direct closure/deletion verification rejected the witness")
    family = width4_crowded_pumping_family!(audit, result.witness_columns)
    base_word = vcat(family.left, family.block, family.right)
    base_grid = [((column >> (row - 1)) & 1) == 1 ? "X" : "." for row in 1:4, column in base_word]
    is_minimal_percolating(base_grid) || error("direct verification rejected the pumping base")
    report = Dict(
        "bound_all_widths_from_1" => result.bound,
        "scope" => "all inclusion-minimal percolating sets, not only largest ones",
        "graph_bound_widths_from_3" => result.graph_bound,
        "states" => result.states, "edges" => result.edges,
        "strong_components" => result.components, "crowded_edges" => result.crowded_edges,
        "crowded_within_component_edges" => 0,
        "witness_columns" => result.witness_columns,
        "witness_verified_by_simulator_and_every_deletion" => true,
        "potential_inequalities_checked" => length(result.edge_values),
        "potential_state_counts" => Dict(string(value) => count(==(value), result.potential) for value in 0:result.bound),
        "pumping_family" => Dict("left" => family.left, "block" => family.block,
                                 "right" => family.right, "minimum_copies" => family.minimum_copies,
                                 "base_width" => family.base_width, "block_gain" => sum(count_ones, family.block)),
    )
    open(path, "w") do io
        println(io, "# Generated by julia experiments/width4_crowded_columns.jl after the complete semantic audit.")
        TOML.print(io, report; sorted = true)
    end
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    result = write_width4_crowded_certificate(isempty(ARGS) ? joinpath(@__DIR__, "results", "width4_crowded_columns.toml") : ARGS[1])
    println("crowded-column bound for every minimal percolating set, every n >= 1 = ", result.bound)
    println("attaining witness = ", result.witness_columns)
    println("pumping family = ", TOML.parsefile(isempty(ARGS) ? joinpath(@__DIR__, "results", "width4_crowded_columns.toml") : ARGS[1])["pumping_family"])
end
