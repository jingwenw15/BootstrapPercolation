if !@isdefined(width4_transition_analysis)
    include("width4_transition_analysis.jl")
end

function width4_seed_column_string(seed_column)
    return join(column_bit(seed_column, row) ? "X" : "." for row in 1:4)
end

function outgoing_edges_by_component(num_vertices, edges, component_id, target_component)
    adjacency = [NamedTuple[] for _ in 1:num_vertices]

    for edge in edges
        if component_id[edge.from] == target_component && component_id[edge.to] == target_component
            push!(adjacency[edge.from], edge)
        end
    end

    return adjacency
end

function reachable_vertices_from(start, adjacency)
    reached = falses(length(adjacency))
    queue = [start]
    reached[start] = true
    cursor = 1

    while cursor <= length(queue)
        vertex = queue[cursor]
        cursor += 1

        for edge in adjacency[vertex]
            if !reached[edge.to]
                reached[edge.to] = true
                push!(queue, edge.to)
            end
        end
    end

    return reached
end

function find_zero_reduced_cycle(adjacency, reduced_weight)
    num_vertices = length(adjacency)

    for start in 1:num_vertices
        isempty(adjacency[start]) && continue

        parent = Dict{Int, NamedTuple}()
        stack = [start]
        on_stack = falses(num_vertices)
        visited = falses(num_vertices)
        next_index = Dict{Int, Int}()

        visited[start] = true
        on_stack[start] = true
        next_index[start] = 1

        while !isempty(stack)
            vertex = stack[end]
            index = next_index[vertex]

            if index > length(adjacency[vertex])
                on_stack[vertex] = false
                pop!(stack)
                continue
            end

            edge = adjacency[vertex][index]
            next_index[vertex] = index + 1
            reduced_weight(edge) == 0 || continue

            if on_stack[edge.to]
                cycle = [edge]
                current = vertex

                while current != edge.to
                    previous_edge = parent[current]
                    push!(cycle, previous_edge)
                    current = previous_edge.from
                end

                reverse!(cycle)
                return cycle
            end

            if !visited[edge.to]
                visited[edge.to] = true
                on_stack[edge.to] = true
                parent[edge.to] = edge
                next_index[edge.to] = 1
                push!(stack, edge.to)
            end
        end
    end

    return nothing
end

function tight_cycle_from_optimal_walk(num_vertices, edges, numerator, denominator; steps = 240)
    neg = typemin(Int) ÷ 4
    score = zeros(Int, num_vertices)
    parents = Vector{Union{Nothing, NamedTuple}}[]

    for _ in 1:steps
        next_score = fill(neg, num_vertices)
        parent = Union{Nothing, NamedTuple}[nothing for _ in 1:num_vertices]

        for edge in edges
            candidate = score[edge.from] + edge.weight
            if candidate > next_score[edge.to]
                next_score[edge.to] = candidate
                parent[edge.to] = edge
            end
        end

        push!(parents, parent)
        score = next_score
    end

    endpoint = argmax(score)
    path_edges = NamedTuple[]
    path_vertices = Int[endpoint]
    current = endpoint

    for step in steps:-1:1
        edge = parents[step][current]
        edge === nothing && break
        push!(path_edges, edge)
        current = edge.from
        push!(path_vertices, current)
    end

    reverse!(path_edges)
    reverse!(path_vertices)

    first_seen = Dict{Int, Int}()
    prefix_weight = zeros(Int, length(path_edges) + 1)

    for i in 1:length(path_edges)
        prefix_weight[i + 1] = prefix_weight[i] + path_edges[i].weight
    end

    for (position, vertex) in enumerate(path_vertices)
        if haskey(first_seen, vertex)
            start = first_seen[vertex]
            stop = position
            weight = prefix_weight[stop] - prefix_weight[start]
            length = stop - start

            if weight * denominator == numerator * length
                return path_edges[start:(stop - 1)]
            end
        else
            first_seen[vertex] = position
        end
    end

    return nothing
end

function max_mean_cycle_certificate(; warmup_cols = 3, max_states = 250_000)
    result = width4_transition_analysis(; warmup_cols = warmup_cols, max_states = max_states, walk_steps = 12)
    graph = result.graph
    graph.truncated && error("transition graph was truncated")

    component_id = zeros(Int, length(graph.states))
    for (id, component) in enumerate(result.components)
        for vertex in component
            component_id[vertex] = id
        end
    end

    best = nothing

    for component in result.cyclic_components
        original_component_id = component_id[component[1]]
        vertices = sort(component)
        local_index = Dict(vertex => i for (i, vertex) in enumerate(vertices))
        local_edges = [
            (
                from = local_index[edge.from],
                to = local_index[edge.to],
                global_from = edge.from,
                global_to = edge.to,
                seed_column = edge.seed_column,
                weight = edge.weight,
            )
            for edge in graph.edges
            if haskey(local_index, edge.from) && haskey(local_index, edge.to)
        ]

        n = length(vertices)
        neg = typemin(Int) ÷ 4
        dp = fill(neg, n + 1, n)
        parent = fill(0, n + 1, n)
        dp[1, :] .= 0

        for k in 1:n
            for edge in local_edges
                candidate = dp[k, edge.from] + edge.weight
                if candidate > dp[k + 1, edge.to]
                    dp[k + 1, edge.to] = candidate
                    parent[k + 1, edge.to] = edge.from
                end
            end
        end

        for v in 1:n
            dp[n + 1, v] == neg && continue

            min_numerator = typemax(Int)
            min_denominator = 1

            for k in 0:(n - 1)
                dp[k + 1, v] == neg && continue
                numerator = dp[n + 1, v] - dp[k + 1, v]
                denominator = n - k

                if numerator * min_denominator < min_numerator * denominator
                    min_numerator = numerator
                    min_denominator = denominator
                end
            end

            if best === nothing || min_numerator * best.denominator > best.numerator * min_denominator
                best = (
                    numerator = min_numerator,
                    denominator = min_denominator,
                    component_id = original_component_id,
                    component_size = length(component),
                    vertex = vertices[v],
                    local_vertex = v,
                )
            end
        end
    end

    best === nothing && error("no cyclic component found")

    numerator = best.numerator
    denominator = best.denominator
    divisor = gcd(numerator, denominator)
    numerator = numerator ÷ divisor
    denominator = denominator ÷ divisor
    cycle = tight_cycle_from_optimal_walk(length(graph.states), graph.edges, numerator, denominator)
    cycle === nothing && error("could not recover a tight cycle")

    return (
        numerator = numerator,
        denominator = denominator,
        component_id = best.component_id,
        component_size = best.component_size,
        cycle = cycle,
        states = graph.states,
    )
end

function print_width4_cycle_certificate(certificate)
    println("max_mean = ", certificate.numerator, "/", certificate.denominator)
    println("component_id = ", certificate.component_id)
    println("component_size = ", certificate.component_size)
    println("cycle_length = ", length(certificate.cycle))
    println("cycle_weight = ", sum(edge.weight for edge in certificate.cycle))
    println("seed_columns = ", join((edge.seed_column for edge in certificate.cycle), ","))
    println("seed_column_strings = ", join((width4_seed_column_string(edge.seed_column) for edge in certificate.cycle), ","))
end

if abspath(PROGRAM_FILE) == @__FILE__
    print_width4_cycle_certificate(max_mean_cycle_certificate())
end
