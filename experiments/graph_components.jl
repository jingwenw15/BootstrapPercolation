function strongly_connected_components(num_vertices, edges)
    adjacency = [Int[] for _ in 1:num_vertices]
    for edge in edges
        push!(adjacency[edge.from], edge.to)
    end
    index = 0
    stack = Int[]
    on_stack = falses(num_vertices)
    indices = fill(0, num_vertices)
    lowlink = fill(0, num_vertices)
    components = Vector{Int}[]

    function strongconnect(v)
        index += 1
        indices[v] = index
        lowlink[v] = index
        push!(stack, v)
        on_stack[v] = true
        for w in adjacency[v]
            if indices[w] == 0
                strongconnect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elseif on_stack[w]
                lowlink[v] = min(lowlink[v], indices[w])
            end
        end
        if lowlink[v] == indices[v]
            component = Int[]
            while true
                w = pop!(stack)
                on_stack[w] = false
                push!(component, w)
                w == v && break
            end
            push!(components, component)
        end
    end
    for v in 1:num_vertices
        indices[v] == 0 && strongconnect(v)
    end
    return components
end

function graph_condensation(num_vertices, edges)
    components = strongly_connected_components(num_vertices, edges)
    component_of = zeros(Int, num_vertices)
    for (id, component) in enumerate(components), vertex in component
        component_of[vertex] = id
    end
    outgoing = [Int[] for _ in components]
    indegree = zeros(Int, length(components))
    for (id, edge) in enumerate(edges)
        source, target = component_of[edge.from], component_of[edge.to]
        source == target && continue
        push!(outgoing[source], id)
        indegree[target] += 1
    end
    order = findall(iszero, indegree)
    cursor = 1
    while cursor <= length(order)
        for id in outgoing[order[cursor]]
            target = component_of[edges[id].to]
            indegree[target] -= 1
            indegree[target] == 0 && push!(order, target)
        end
        cursor += 1
    end
    length(order) == length(components) || error("component condensation is not acyclic")
    return (components = components, component_of = component_of, outgoing = outgoing, order = order)
end
