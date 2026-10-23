struct RectangleMergeNode
    bounds::NTuple{4, Int} # top, bottom, left, right
    seeds::Vector{CartesianIndex{2}}
    children::Tuple{Int, Int}
end

function rectangle_l1_distance(first, second)
    vertical = max(0, max(first[1], second[1]) - min(first[2], second[2]))
    horizontal = max(0, max(first[3], second[3]) - min(first[4], second[4]))
    return vertical + horizontal
end

rectangle_hull(first, second) =
    (min(first[1], second[1]), max(first[2], second[2]),
     min(first[3], second[3]), max(first[4], second[4]))

rectangle_contains(bounds, cell) = bounds[1] <= cell[1] <= bounds[2] && bounds[3] <= cell[2] <= bounds[4]
rectangle_height(bounds) = bounds[2] - bounds[1] + 1

"""
Classical rectangles process with disjoint seed ownership and recorded merges.
This is an eventual-closure diagnostic, not a synchronous simulation or clock.
It does not modify the input and does not use the semantic state graph.
"""
function rectangle_merge_tree(grid)
    all(cell -> cell in (".", "X"), grid) || throw(ArgumentError("invalid grid cell"))
    nodes = [RectangleMergeNode((cell[1], cell[1], cell[2], cell[2]), [cell], (0, 0))
             for cell in findall(==("X"), grid)]
    active = collect(eachindex(nodes))
    while true
        pair = nothing
        for i in eachindex(active), j in (i + 1):length(active)
            rectangle_l1_distance(nodes[active[i]].bounds, nodes[active[j]].bounds) <= 2 || continue
            pair = (i, j)
            break
        end
        pair === nothing && break
        i, j = pair
        left, right = active[i], active[j]
        push!(nodes, RectangleMergeNode(rectangle_hull(nodes[left].bounds, nodes[right].bounds),
                                       vcat(nodes[left].seeds, nodes[right].seeds), (left, right)))
        deleteat!(active, j)
        deleteat!(active, i)
        push!(active, length(nodes))
    end
    return (nodes = nodes, active = active)
end

function first_full_height_merge(grid; tree = rectangle_merge_tree(grid))
    height = size(grid, 1)
    height >= 2 || throw(ArgumentError("height must be at least two"))
    index = findfirst(node -> rectangle_height(node.bounds) == height, tree.nodes)
    index === nothing && throw(ArgumentError("no full-height internally spanned rectangle"))
    node = tree.nodes[index]
    left, right = tree.nodes[node.children[1]], tree.nodes[node.children[2]]
    left_columns = Set(cell[2] for cell in left.seeds)
    right_columns = Set(cell[2] for cell in right.seeds)
    return (node = node, left = left, right = right,
            mixed_columns = sort!(collect(intersect(left_columns, right_columns))),
            tree = tree)
end

function rectangle_node_grid(node)
    top, bottom, left, right = node.bounds
    grid = fill(".", bottom - top + 1, right - left + 1)
    for cell in node.seeds
        grid[cell[1] - top + 1, cell[2] - left + 1] = "X"
    end
    return grid
end

rectangle_seed_crowded_count(seeds) = count(col -> count(cell -> cell[2] == col, seeds) >= 2,
                                           unique(cell[2] for cell in seeds))

"""Verify an explicit nonpercolation witness, without running the dynamics."""
function verify_deletion_fort_columns(grid, removed, columns)
    height, width = size(grid)
    length(columns) == width || return false
    checkbounds(Bool, grid, removed) || return false
    grid[removed] == "X" || return false
    all(column -> column isa Integer && column >= 0 && (column >> height) == 0, columns) || return false
    fort = [((column >> (row - 1)) & 1) == 1 for row in 1:height, column in columns]
    fort[removed] || return false
    for cell in CartesianIndices(grid)
        fort[cell] || continue
        cell != removed && grid[cell] == "X" && return false
        outside = 0
        for offset in (CartesianIndex(-1, 0), CartesianIndex(1, 0), CartesianIndex(0, -1), CartesianIndex(0, 1))
            neighbor = cell + offset
            checkbounds(Bool, fort, neighbor) && !fort[neighbor] && (outside += 1)
        end
        outside <= 1 || return false
    end
    return true
end
