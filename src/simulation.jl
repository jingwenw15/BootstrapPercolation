using DataStructures

grid = ["." "X" "." ; "X" "." "X"; "." "X" "."]

function simulate(grid)
    queue = Queue{CartesianIndex{2}}()
    freq = DefaultDict{CartesianIndex{2}, Int}(0)

    R, C = size(grid)

    offsets = (CartesianIndex(1, 0), CartesianIndex(-1, 0), CartesianIndex(0, 1), CartesianIndex(0, -1))

    for j in 1:C, i in 1:R 
        cur = CartesianIndex(i, j)

        if grid[cur] == "."
            infectedNeighbors = 0

            for offset in offsets
                neighbor = cur + offset 

                if 1 <= neighbor[1] <= R && 1 <= neighbor[2] <= C && grid[neighbor] == "X"
                    infectedNeighbors += 1
                end
            end 

            freq[cur] = infectedNeighbors
            if infectedNeighbors >= 2
                enqueue!(queue, cur)
            end
        end
    end

    time = 0

    while !isempty(queue)
        levelSize = length(queue)

        for _ in 1:levelSize
            cur = dequeue!(queue)
            grid[cur] = "X"

            for offset in offsets
                neighbor = cur + offset 

                if 1 <= neighbor[1] <= R && 1 <= neighbor[2] <= C && grid[neighbor] == "."
                    freq[neighbor] += 1

                    if freq[neighbor] == 2
                        enqueue!(queue, neighbor)
                    end
                end
            end
        end

        time += 1
    end

    return grid, all(grid .== "X"), time
end