include("width4_minimality_dp.jl")

function require_equal(label, actual, expected)
    if actual != expected
        error("$(label): expected $(expected), got $(actual)")
    end

    println("verified: ", label, " = ", actual)
end

function require_file_contains(path, text)
    contents = read(path, String)

    if !occursin(text, contents)
        error("$(path) does not contain expected text: $(text)")
    end

    println("verified: ", path, " contains `", text, "`")
end

function verify_witness_pruned_layers()
    expected = Dict(
        (4, 5) => (raw = 360, classes = 90),
        (5, 6) => (raw = 280, classes = 73),
        (8, 8) => (raw = 7074, classes = 1778),
    )

    for ((cols, size), values) in sort(collect(expected))
        result = width4_find_minimal_by_witness_pruning(cols, size; store = false)

        require_equal("4 x $(cols), size $(size), raw minimal sets", result.raw_maximizers, values.raw)
        require_equal("4 x $(cols), size $(size), symmetry classes", result.symmetry_classes, values.classes)
        require_equal("4 x $(cols), size $(size), generated minimal candidates", result.generated_minimal, values.raw)
    end
end

function verify_4x9_certificate_files()
    require_file_contains("experiments/results/fast_exact_4x9_size11_generated.txt", "minimal percolating = 0")
    require_file_contains("experiments/results/fast_exact_4x9_size10_generated_canonical.txt", "raw minimal percolating = 0")
    require_file_contains("experiments/results/fast_exact_4x9_size9_generated_canonical.txt", "raw minimal percolating = 1312")
    require_file_contains("experiments/results/fast_exact_4x9_size9_generated_canonical.txt", "symmetry classes = 328")
end

function verify_4x10_construction()
    example = bitmask_from_positions(4, 10, [1, 2, 8, 9, 14, 15, 29, 30, 35, 36])

    require_equal("4 x 10 construction size", count_ones(example), 10)
    require_equal("4 x 10 construction is minimal percolating", width4_is_minimal_percolating_by_witness_summary(10, example), true)
end

function verify_4x10_dp_counts()
    expected = Dict(
        12 => (viable = 388350293, percolating = 256942360),
        11 => (viable = 309117476, percolating = 159572568),
        10 => (viable = 192959628, percolating = 68033874),
    )

    for (size, values) in sort(collect(expected); by = pair -> -pair.first)
        require_equal("4 x 10, size $(size), locally viable", width4_locally_viable_count(10, size), values.viable)
        require_equal("4 x 10, size $(size), locally viable percolating", width4_locally_viable_percolating_count(10, size), values.percolating)
    end
end

function verify_4x10_merged_state_certificate()
    expected = Dict(
        12 => 0,
        11 => 0,
        10 => 82,
    )

    for (size, count) in sort(collect(expected); by = pair -> -pair.first)
        result = width4_count_minimal_by_merged_state(10, size)
        require_equal("4 x 10, size $(size), merged-state minimal count", result.raw_minimal_percolating, count)
    end
end

function verify_4x11_merged_state_certificate()
    expected = Dict(
        13 => 0,
        12 => 0,
        11 => 0,
        10 => 145332,
    )

    for (size, count) in sort(collect(expected); by = pair -> -pair.first)
        result = width4_count_minimal_by_merged_state(11, size)
        require_equal("4 x 11, size $(size), merged-state minimal count", result.raw_minimal_percolating, count)
    end
end

function verify_4x12_merged_state_certificate()
    expected = Dict(
        14 => 0,
        13 => 0,
        12 => 0,
        11 => 28640,
    )

    for (size, count) in sort(collect(expected); by = pair -> -pair.first)
        result = width4_count_minimal_by_merged_state(12, size)
        require_equal("4 x 12, size $(size), merged-state minimal count", result.raw_minimal_percolating, count)
    end
end

function verify_width4_findings()
    verify_4x9_certificate_files()
    verify_4x10_construction()
    verify_4x10_dp_counts()
    verify_4x10_merged_state_certificate()
    verify_4x11_merged_state_certificate()
    verify_4x12_merged_state_certificate()
    verify_witness_pruned_layers()
    println("width-4 findings verified")
end

if abspath(PROGRAM_FILE) == @__FILE__
    verify_width4_findings()
end
