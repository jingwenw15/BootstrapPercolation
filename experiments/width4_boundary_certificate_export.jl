if !@isdefined(width4_boundary_recurrence_certificate)
    include("width4_boundary_recurrence.jl")
end

function write_width4_boundary_certificate(prefix; warmup_cols = 3, max_states = 250_000)
    graph = width4_interior_transition_graph(; warmup_cols = warmup_cols, max_states = max_states)
    graph.truncated && error("transition graph was truncated")
    core = width4_boundary_core(graph)
    warmup_scores = width4_warmup_scores(warmup_cols)
    vertices_path = prefix * "_vertices.csv"
    edges_path = prefix * "_edges.csv"
    metadata_path = prefix * "_metadata.txt"

    open(vertices_path, "w") do io
        println(io, "id,accepting,initial_score")

        for (id, state) in enumerate(graph.states)
            score = get(warmup_scores, state, nothing)
            println(io, id, ",", core.accepting[id] ? 1 : 0, ",", score === nothing ? "NA" : score)
        end
    end

    open(edges_path, "w") do io
        println(io, "from_state,to_state,weight")
        for edge in graph.edges
            println(io, edge.from, ",", edge.to, ",", edge.weight)
        end
    end

    open(metadata_path, "w") do io
        println(io, "warmup_cols = ", warmup_cols)
        println(io, "states = ", length(graph.states))
        println(io, "edges = ", length(graph.edges))
        println(io, "accepting_states = ", core.accepting_count)
        println(io, "boundary_core_states = ", core.state_count)
        println(io, "boundary_core_edges = ", core.edge_count)
        println(io, "claimed_period = 3")
        println(io, "claimed_gain = 2")
        println(io, "claimed_recurrence_start = 19")
        println(io, "claimed_recurrence_end = 22")
        println(io, "vertices_csv = ", basename(vertices_path))
        println(io, "edges_csv = ", basename(edges_path))
    end

    return (
        vertices_path = vertices_path,
        edges_path = edges_path,
        metadata_path = metadata_path,
        states = length(graph.states),
        edges = length(graph.edges),
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    default_prefix = joinpath(@__DIR__, "results", "width4_boundary_certificate")
    prefix = isempty(ARGS) ? default_prefix : ARGS[1]
    result = write_width4_boundary_certificate(prefix)
    println("vertices = ", result.vertices_path)
    println("edges = ", result.edges_path)
    println("metadata = ", result.metadata_path)
end
