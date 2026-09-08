if !@isdefined(percolates)
    include("simulation.jl")
end

function is_minimal_percolating(grid)
    if !percolates(grid)
        return false
    end

    R, C = size(grid)
    for j in 1:C, i in 1:R
        cur = CartesianIndex(i, j)
        if grid[cur] == "X"
            state = copy(grid)
            state[cur] = "."
            if percolates(state)
                return false
            end
        end
    end

    return true
end
