if !@isdefined(is_minimal_percolating)
    include("../src/minimal.jl")
end

"""
    extend_minimal_percolating(grid; row = nothing)

Extend a nonempty minimal percolating grid by one column without losing seeds.
Morris (2009), Lemma 7: move a right-boundary seed into the new column if that
percolates; otherwise retain the old seed and add its new neighbor. The result
is minimal and has either the original number of seeds or one more. Inputs
are validated and never mutated. `row` may select any infected boundary cell.
"""
function extend_minimal_percolating(grid; row = nothing)
    height, cols = size(grid)
    height >= 1 && cols >= 1 || throw(ArgumentError("grid must be nonempty"))
    all(cell -> cell in ("X", "."), grid) || throw(ArgumentError("cells must be X or ."))
    is_minimal_percolating(grid) || throw(ArgumentError("grid must be minimal percolating"))

    anchor_row = row === nothing ? findfirst(==("X"), view(grid, :, cols)) : row
    anchor_row isa Integer && 1 <= anchor_row <= height ||
        throw(ArgumentError("row must identify an infected right-boundary cell"))
    grid[anchor_row, cols] == "X" ||
        throw(ArgumentError("row must identify an infected right-boundary cell"))

    extended = fill(".", height, cols + 1)
    extended[:, 1:cols] .= grid
    extended[anchor_row, cols + 1] = "X"
    extended[anchor_row, cols] = "."

    if percolates(extended)
        mode = :move
    else
        extended[anchor_row, cols] = "X"
        mode = :add
    end

    return (grid = extended, mode = mode, anchor_row = Int(anchor_row))
end
