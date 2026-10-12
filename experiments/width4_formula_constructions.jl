if !@isdefined(width4_boundary_recurrence_certificate)
    include("width4_boundary_recurrence.jl")
end

function width4_columns_to_grid(columns)
    return [
        column_bit(columns[col], row) ? "X" : "."
        for row in 1:4, col in eachindex(columns)
    ]
end

function width4_formula_construction(cols)
    cols >= 9 || throw(ArgumentError("the repeating construction requires at least nine columns"))

    repeating_block = [1, 1, 0]
    right_boundary = [2, 10, 8, 0, 1, 5, 4]
    residue = mod(cols, 3)

    if residue == 0
        left_boundary = [2, 0]
        base_cols = 9
    elseif residue == 1
        left_boundary = Int[]
        base_cols = 7
    else
        left_boundary = [2, 0, 1, 0]
        base_cols = 11
    end

    block_count = (cols - base_cols) ÷ 3
    seed_columns = vcat(left_boundary, repeat(repeating_block, block_count), right_boundary)
    grid = width4_columns_to_grid(seed_columns)

    return (
        cols = cols,
        size = count(==("X"), grid),
        seed_columns = seed_columns,
        grid = grid,
        verified_minimal_percolating = is_minimal_percolating(grid),
    )
end

function width4_advance_seed_path(columns)
    state = (0, 0, initial_stable_bits(), Tuple(Width4StableBits[]))

    for (col, seed_column) in enumerate(columns)
        state = advance_width4_interior_state(state, seed_column, col; right_exists = true)
        state === nothing && return nothing
    end

    return state
end

function width4_advance_stationary_path(state, columns)
    for seed_column in columns
        state = advance_width4_interior_state(state, seed_column, 3; right_exists = true)
        state === nothing && return nothing
    end

    return state
end

function width4_formula_construction_certificate()
    repeating_block = [1, 1, 0]
    right_boundary = [2, 10, 8, 0, 1, 5, 4]
    residue_specs = (
        (residue = 0, left_boundary = [2, 0], base_cols = 9),
        (residue = 1, left_boundary = Int[], base_cols = 10),
        (residue = 2, left_boundary = [2, 0, 1, 0], base_cols = 11),
    )
    loops = NamedTuple[]

    for spec in residue_specs
        first_state = width4_advance_seed_path(vcat(spec.left_boundary, repeating_block))
        first_state === nothing && error("construction prefix was rejected")
        second_state = width4_advance_stationary_path(first_state, repeating_block)
        final_state = width4_advance_stationary_path(first_state, right_boundary)

        push!(
            loops,
            (
                residue = spec.residue,
                returns_to_same_state = second_state == first_state,
                suffix_accepts = final_state !== nothing && width4_is_accepting_state(final_state, 3),
                base_cols = spec.base_cols,
                base_is_minimal_percolating = width4_formula_construction(spec.base_cols).verified_minimal_percolating,
            ),
        )
    end

    return (
        block = repeating_block,
        block_weight = sum(column_seed_count(column) for column in repeating_block),
        block_length = length(repeating_block),
        loops = loops,
    )
end

function width4_warmup_paths(warmup_cols)
    initial_state = (0, 0, initial_stable_bits(), Tuple(Width4StableBits[]))
    paths = Dict{Width4InteriorState, NamedTuple{(:weight, :columns), Tuple{Int, Tuple{Vararg{Int}}}}}()
    paths[initial_state] = (weight = 0, columns = ())

    for col in 1:warmup_cols
        next_paths = Dict{Width4InteriorState, NamedTuple{(:weight, :columns), Tuple{Int, Tuple{Vararg{Int}}}}}()

        for (state, path) in paths
            for seed_column in 0:15
                next_state = advance_width4_interior_state(state, seed_column, col; right_exists = true)
                next_state === nothing && continue
                candidate = path.weight + column_seed_count(seed_column)

                if !haskey(next_paths, next_state) || candidate > next_paths[next_state].weight
                    next_paths[next_state] = (weight = candidate, columns = (path.columns..., seed_column))
                end
            end
        end

        paths = next_paths
    end

    return paths
end

function width4_core_adjacency(graph, core)
    adjacency = [NamedTuple[] for _ in graph.states]

    for edge in graph.edges
        core.coaccessible[edge.from] && core.coaccessible[edge.to] || continue
        push!(adjacency[edge.from], edge)
    end

    return adjacency
end

function width4_suffix_scores(graph, core, steps)
    adjacency = width4_core_adjacency(graph, core)
    scores = fill(WIDTH4_NEGATIVE_INFINITY, length(graph.states))

    for vertex in eachindex(scores)
        core.accepting[vertex] && (scores[vertex] = 0)
    end

    layers = Vector{Int}[scores]

    for _ in 1:steps
        next_scores = fill(WIDTH4_NEGATIVE_INFINITY, length(graph.states))

        for vertex in eachindex(next_scores)
            core.coaccessible[vertex] || continue

            for edge in adjacency[vertex]
                scores[edge.to] == WIDTH4_NEGATIVE_INFINITY && continue
                next_scores[vertex] = max(next_scores[vertex], edge.weight + scores[edge.to])
            end
        end

        scores = next_scores
        push!(layers, scores)
    end

    return layers, adjacency
end

function width4_extremal_witness(cols; graph = nothing, core = nothing)
    cols >= 3 || throw(ArgumentError("witness extraction requires at least three columns"))
    graph === nothing && (graph = width4_interior_transition_graph())
    graph.truncated && error("transition graph was truncated")
    core === nothing && (core = width4_boundary_core(graph))

    ids = Dict(state => id for (id, state) in enumerate(graph.states))
    remaining_steps = cols - graph.warmup_cols
    suffix_layers, adjacency = width4_suffix_scores(graph, core, remaining_steps)
    warmup_paths = width4_warmup_paths(graph.warmup_cols)
    best = WIDTH4_NEGATIVE_INFINITY
    current = 0
    columns = Int[]

    for (state, path) in warmup_paths
        vertex = ids[state]
        suffix = suffix_layers[remaining_steps + 1][vertex]
        suffix == WIDTH4_NEGATIVE_INFINITY && continue
        candidate = path.weight + suffix

        if candidate > best
            best = candidate
            current = vertex
            columns = collect(path.columns)
        end
    end

    best == WIDTH4_NEGATIVE_INFINITY && error("no accepting width-four path found")

    for steps_left in remaining_steps:-1:1
        target_score = suffix_layers[steps_left + 1][current]
        chosen = nothing

        for edge in adjacency[current]
            suffix = suffix_layers[steps_left][edge.to]
            if suffix != WIDTH4_NEGATIVE_INFINITY && edge.weight + suffix == target_score
                chosen = edge
                break
            end
        end

        chosen === nothing && error("could not reconstruct optimal path")
        push!(columns, chosen.seed_column)
        current = chosen.to
    end

    grid = width4_columns_to_grid(columns)
    mask = nothing

    if 4 * cols <= 64
        packed = UInt64(0)
        for (col, seed_column) in enumerate(columns)
            packed = append_column_mask(4, cols, packed, col, seed_column)
        end
        mask = packed
    end

    return (
        cols = cols,
        size = best,
        seed_columns = columns,
        grid = grid,
        mask = mask,
        verified_minimal_percolating = is_minimal_percolating(grid),
    )
end

function print_width4_extremal_witness(witness)
    println("4 x ", witness.cols, ", size ", witness.size)
    println("seed columns: ", join(witness.seed_columns, ","))
    for row in 1:4
        println(join((column_bit(seed_column, row) ? "X" : "." for seed_column in witness.seed_columns), " "))
    end
    println("verified minimal percolating: ", witness.verified_minimal_percolating)
end

if abspath(PROGRAM_FILE) == @__FILE__
    requested_cols = isempty(ARGS) ? [19, 20, 21] : parse.(Int, ARGS)
    graph = width4_interior_transition_graph()
    core = width4_boundary_core(graph)

    for (index, cols) in enumerate(requested_cols)
        index > 1 && println()
        witness = width4_extremal_witness(cols; graph = graph, core = core)
        print_width4_extremal_witness(witness)
    end
end
