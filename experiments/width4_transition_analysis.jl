if !@isdefined(width4_interior_transition_graph)
    include("width4_transition_export.jl")
end

if !@isdefined(strongly_connected_components)
    include("graph_components.jl")
end

function max_weight_walk_profile(num_vertices, edges, steps)
    neg = typemin(Int) ÷ 4
    current = zeros(Int, num_vertices)
    profile = Int[]

    for _ in 1:steps
        next = fill(neg, num_vertices)

        for edge in edges
            candidate = current[edge.from] + edge.weight
            if candidate > next[edge.to]
                next[edge.to] = candidate
            end
        end

        current = next
        push!(profile, maximum(current))
    end

    return profile
end

function width4_transition_analysis(; warmup_cols = 3, max_states = 250_000, walk_steps = 80)
    graph = width4_interior_transition_graph(; warmup_cols = warmup_cols, max_states = max_states)
    components = strongly_connected_components(length(graph.states), graph.edges)
    component_id = zeros(Int, length(graph.states))

    for (id, component) in enumerate(components)
        for vertex in component
            component_id[vertex] = id
        end
    end

    self_loop_components = Set{Int}()
    for edge in graph.edges
        if edge.from == edge.to
            push!(self_loop_components, component_id[edge.from])
        end
    end

    cyclic_components = [
        component for (id, component) in enumerate(components)
        if length(component) > 1 || id in self_loop_components
    ]

    profile = max_weight_walk_profile(length(graph.states), graph.edges, walk_steps)
    increments = [profile[i] - (i == 1 ? 0 : profile[i - 1]) for i in 1:length(profile)]

    return (
        graph = graph,
        components = components,
        cyclic_components = cyclic_components,
        largest_component = maximum(length.(components)),
        largest_cyclic_component = isempty(cyclic_components) ? 0 : maximum(length.(cyclic_components)),
        walk_profile = profile,
        walk_increments = increments,
    )
end

function print_width4_transition_analysis(result)
    println("states = ", length(result.graph.states))
    println("transitions = ", length(result.graph.edges))
    println("truncated = ", result.graph.truncated)
    println("strong components = ", length(result.components))
    println("cyclic components = ", length(result.cyclic_components))
    println("largest component = ", result.largest_component)
    println("largest cyclic component = ", result.largest_cyclic_component)
    println("max-weight walk profile = ", join(result.walk_profile, ","))
    println("max-weight walk increments = ", join(result.walk_increments, ","))
end

if abspath(PROGRAM_FILE) == @__FILE__
    walk_steps = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 80
    print_width4_transition_analysis(width4_transition_analysis(; walk_steps = walk_steps))
end
