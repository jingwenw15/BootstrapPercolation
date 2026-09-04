include("../src/simulation.jl")

grid = [
    "." "X" ".";
    "X" "." ".";
    "." "." "."
]

finalGrid, percolated, time, history = simulate(grid)

for (t, state) in enumerate(history)
    println("Time $(t-1):")
    display(state)
    println()
end 

println("Percolated: ", percolated)
println("Time: ", time)