include("../src/simulation.jl")

grid = [
    "." "X" ".";
    "X" "." ".";
    "." "." "."
]

finalGrid, percolated, time, history = simulate(grid)

for (t, state) in enumerate(history)
    println("Time $(t-1):")
    for row in eachrow(state) 
        println(join(row, " "))
    end
    println()
end 

println("Percolated: ", percolated)
println("Time: ", time)