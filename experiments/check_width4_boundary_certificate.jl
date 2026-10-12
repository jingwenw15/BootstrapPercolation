const CERTIFICATE_NEGATIVE_INFINITY = typemin(Int) ÷ 4

function read_width4_certificate_vertices(path)
    accepting = Bool[]
    initial_scores = Int[]

    open(path, "r") do io
        readline(io) == "id,accepting,initial_score" || error("invalid vertex header")

        for line in eachline(io)
            fields = split(line, ',')
            length(fields) == 3 || error("invalid vertex row: $(line)")
            id = parse(Int, fields[1])
            id == length(accepting) + 1 || error("vertex IDs must be consecutive")
            fields[2] in ("0", "1") || error("invalid accepting flag at vertex $(id)")
            push!(accepting, fields[2] == "1")
            score = fields[3] == "NA" ? CERTIFICATE_NEGATIVE_INFINITY : parse(Int, fields[3])
            score == CERTIFICATE_NEGATIVE_INFINITY || 0 <= score <= 12 ||
                error("invalid warm-up score at vertex $(id)")
            push!(initial_scores, score)
        end
    end

    return accepting, initial_scores
end

function read_width4_certificate_edges(path, num_vertices)
    edges = NamedTuple{(:from, :to, :weight), Tuple{Int, Int, Int}}[]

    open(path, "r") do io
        readline(io) == "from_state,to_state,weight" || error("invalid edge header")

        for line in eachline(io)
            fields = split(line, ',')
            length(fields) == 3 || error("invalid edge row: $(line)")
            from = parse(Int, fields[1])
            to = parse(Int, fields[2])
            weight = parse(Int, fields[3])
            1 <= from <= num_vertices || error("invalid source vertex $(from)")
            1 <= to <= num_vertices || error("invalid target vertex $(to)")
            0 <= weight <= 4 || error("invalid edge weight $(weight)")
            push!(edges, (from = from, to = to, weight = weight))
        end
    end

    return edges
end

function reverse_reachable_vertices(num_vertices, edges, targets)
    reverse_adjacency = [Int[] for _ in 1:num_vertices]
    for edge in edges
        push!(reverse_adjacency[edge.to], edge.from)
    end

    reached = copy(targets)
    queue = findall(targets)
    cursor = 1

    while cursor <= length(queue)
        vertex = queue[cursor]
        cursor += 1

        for predecessor in reverse_adjacency[vertex]
            if !reached[predecessor]
                reached[predecessor] = true
                push!(queue, predecessor)
            end
        end
    end

    return reached
end


function forward_reachable_vertices(num_vertices, edges, initial_scores)
    adjacency = [Int[] for _ in 1:num_vertices]
    for edge in edges
        push!(adjacency[edge.from], edge.to)
    end

    reached = BitVector(score != CERTIFICATE_NEGATIVE_INFINITY for score in initial_scores)
    queue = findall(reached)
    cursor = 1

    while cursor <= length(queue)
        vertex = queue[cursor]
        cursor += 1

        for successor in adjacency[vertex]
            if !reached[successor]
                reached[successor] = true
                push!(queue, successor)
            end
        end
    end

    return reached
end

function advance_certificate_scores(scores, edges, core)
    next_scores = fill(CERTIFICATE_NEGATIVE_INFINITY, length(scores))

    for edge in edges
        core[edge.from] && core[edge.to] || continue
        scores[edge.from] == CERTIFICATE_NEGATIVE_INFINITY && continue
        candidate = scores[edge.from] + edge.weight
        next_scores[edge.to] = max(next_scores[edge.to], candidate)
    end

    return next_scores
end

function certificate_vectors_differ_by(left, right, core, gain)
    for vertex in eachindex(core)
        core[vertex] || continue

        if left[vertex] == CERTIFICATE_NEGATIVE_INFINITY
            right[vertex] == CERTIFICATE_NEGATIVE_INFINITY || return false
        elseif right[vertex] != left[vertex] + gain
            return false
        end
    end

    return true
end

function check_width4_boundary_certificate(
    vertices_path = joinpath(@__DIR__, "results", "width4_boundary_certificate_vertices.csv"),
    edges_path = joinpath(@__DIR__, "results", "width4_boundary_certificate_edges.csv"),
)
    accepting, initial_scores = read_width4_certificate_vertices(vertices_path)
    edges = read_width4_certificate_edges(edges_path, length(accepting))
    length(accepting) == 26009 || error("expected 26009 states, found $(length(accepting))")
    length(edges) == 114602 || error("expected 114602 edges, found $(length(edges))")
    count(accepting) == 8924 || error("expected 8924 accepting states, found $(count(accepting))")
    core = reverse_reachable_vertices(length(accepting), edges, accepting)
    forward = forward_reachable_vertices(length(accepting), edges, initial_scores)
    all(forward) || error("certificate graph contains a state unreachable from the warm-up boundary")
    count(core) == 15150 || error("expected 15150 boundary-core states, found $(count(core))")

    scores = copy(initial_scores)
    scores[.!core] .= CERTIFICATE_NEGATIVE_INFINITY
    values = Dict{Int, Int}()
    score_at_19 = nothing

    for col in 3:22
        accepting_scores = scores[accepting]
        isempty(accepting_scores) && error("certificate has no accepting states")
        best = maximum(accepting_scores)
        best == CERTIFICATE_NEGATIVE_INFINITY && error("no accepted path at column $(col)")
        values[col] = best

        col == 19 && (score_at_19 = copy(scores))
        if col == 22
            score_at_19 === nothing && error("missing column-19 score vector")
            certificate_vectors_differ_by(score_at_19, scores, core, 2) ||
                error("column-22 score vector is not column-19 plus two")
            break
        end

        scores = advance_certificate_scores(scores, edges, core)
    end

    for n in 5:22
        expected = fld(2 * n + 10, 3)
        values[n] == expected || error("formula mismatch at n=$(n): $(values[n]) != $(expected)")
    end

    core_edges = count(edge -> core[edge.from] && core[edge.to], edges)
    core_edges == 46618 || error("expected 46618 boundary-core edges, found $(core_edges)")

    return (
        verified = true,
        states = length(accepting),
        edges = length(edges),
        accepting_states = count(accepting),
        core_states = count(core),
        core_edges = core_edges,
        recurrence_start = 19,
        recurrence_end = 22,
        period = 3,
        gain = 2,
        values = values,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    vertices_path = length(ARGS) >= 1 ? ARGS[1] : joinpath(@__DIR__, "results", "width4_boundary_certificate_vertices.csv")
    edges_path = length(ARGS) >= 2 ? ARGS[2] : joinpath(@__DIR__, "results", "width4_boundary_certificate_edges.csv")
    result = check_width4_boundary_certificate(vertices_path, edges_path)

    println("verified = ", result.verified)
    println("states = ", result.states)
    println("edges = ", result.edges)
    println("accepting_states = ", result.accepting_states)
    println("boundary_core_states = ", result.core_states)
    println("boundary_core_edges = ", result.core_edges)
    println("score_vector_recurrence = v_", result.recurrence_end, " = v_", result.recurrence_start, " + ", result.gain)
    println("formula_verified_for_n = 5..22")
end
