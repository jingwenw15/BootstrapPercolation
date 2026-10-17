include("width4_graph_acceptance.jl")
include("width4_cycle_certificate.jl")
include("width4_boundary_recurrence.jl")
include("width4_formula_constructions.jl")
include("check_width4_boundary_certificate.jl")
include("check_width4_semantic_certificate.jl")

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

function verify_graph_acceptance_table()
    expected = Dict(
        4 => (maximum_size = 5, raw = 360),
        5 => (maximum_size = 6, raw = 280),
        6 => (maximum_size = 7, raw = 40),
        7 => (maximum_size = 8, raw = 2),
        8 => (maximum_size = 8, raw = 7074),
        9 => (maximum_size = 9, raw = 1312),
        10 => (maximum_size = 10, raw = 82),
        11 => (maximum_size = 10, raw = 145332),
        12 => (maximum_size = 11, raw = 28640),
    )

    for (cols, values) in sort(collect(expected))
        result = width4_graph_acceptance_value(cols)
        require_equal("4 x $(cols), graph-acceptance E(4,n)", result.maximum_size, values.maximum_size)
        require_equal("4 x $(cols), graph-acceptance raw maximizers", result.raw_maximizers, values.raw)
    end
end

function verify_width4_cycle_certificate()
    certificate = max_mean_cycle_certificate()

    require_equal("width-4 interior max mean numerator", certificate.numerator, 4)
    require_equal("width-4 interior max mean denominator", certificate.denominator, 3)
    require_equal(
        "width-4 recovered cycle is tight",
        sum(edge.weight for edge in certificate.cycle) * certificate.denominator,
        certificate.numerator * length(certificate.cycle),
    )
end

function verify_width4_boundary_recurrence()
    certificate = width4_boundary_recurrence_certificate()

    require_equal("width-4 boundary-core states", certificate.core_states, 15150)
    require_equal("width-4 boundary-core transitions", certificate.core_edges, 46618)
    require_equal("width-4 score-vector period", certificate.period, 3)
    require_equal("width-4 score-vector gain", certificate.gain, 2)
    require_equal("width-4 recurrence start", certificate.recurrence_start, 19)
    require_equal("width-4 recurrence verification column", certificate.recurrence_end, 22)

    for n in 5:certificate.recurrence_end
        require_equal("width-4 exact formula at n=$(n)", certificate.values[n], fld(2 * n + 10, 3))
    end
end

function verify_width4_formula_constructions()
    for n in 9:30
        construction = width4_formula_construction(n)
        require_equal("width-4 construction size at n=$(n)", construction.size, fld(2 * n + 10, 3))
        require_equal("width-4 construction minimality at n=$(n)", construction.verified_minimal_percolating, true)
    end

    certificate = width4_formula_construction_certificate()
    require_equal("width-4 repeating block length", certificate.block_length, 3)
    require_equal("width-4 repeating block weight", certificate.block_weight, 2)

    for loop in certificate.loops
        require_equal("width-4 residue $(loop.residue) block closes", loop.returns_to_same_state, true)
        require_equal("width-4 residue $(loop.residue) suffix accepts", loop.suffix_accepts, true)
        require_equal("width-4 residue $(loop.residue) base construction", loop.base_is_minimal_percolating, true)
    end
end

function verify_independent_boundary_certificate()
    certificate = check_width4_boundary_certificate()
    require_equal("independent boundary certificate", certificate.verified, true)
    require_equal("independent certificate states", certificate.states, 26009)
    require_equal("independent certificate transitions", certificate.edges, 114602)
    require_equal("independent certificate core states", certificate.core_states, 15150)
    require_equal("independent certificate core transitions", certificate.core_edges, 46618)
end

function verify_independent_semantic_certificate()
    certificate = Width4SemanticCertificate.check_width4_semantic_certificate()
    require_equal("independent semantic certificate", certificate.verified, true)
    require_equal("independent semantic column choices", certificate.column_choices_checked, 416144)
    require_equal("independent semantic warm-up states", certificate.warmup_states, 496)
end

function verify_width4_findings()
    verify_4x9_certificate_files()
    verify_4x10_construction()
    verify_4x10_dp_counts()
    verify_4x10_merged_state_certificate()
    verify_4x11_merged_state_certificate()
    verify_4x12_merged_state_certificate()
    verify_graph_acceptance_table()
    verify_width4_cycle_certificate()
    verify_width4_boundary_recurrence()
    verify_width4_formula_constructions()
    verify_independent_boundary_certificate()
    verify_independent_semantic_certificate()
    verify_witness_pruned_layers()
    println("width-4 findings verified")
end

if abspath(PROGRAM_FILE) == @__FILE__
    verify_width4_findings()
end
