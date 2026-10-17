include("../experiments/check_width4_semantic_certificate.jl")

@testset "Independent Width-Four Semantic Certificate" begin
    checker = Width4SemanticCertificate
    audit = checker.load_semantic_certificate()

    @testset "Complete graph agrees with independently computed semantics" begin
        result = checker.verify_loaded_semantic_certificate!(audit)
        @test result.verified
        @test result.states == 26009
        @test result.edges == 114602
        @test result.column_choices_checked == 416144
        @test result.warmup_states == 496
        @test result.accepting_states == 8924
        @test result.arithmetic.values[4] == 5
        @test result.arithmetic.recurrence_start == 19
    end

    @testset "Certificate tampering is rejected" begin
        legal = findfirst(!iszero, audit.targets)
        removed_targets = copy(audit.targets)
        removed_targets[legal] = 0
        @test_throws ErrorException checker.check_semantic_transitions!(
            merge(audit, (targets = removed_targets,)); state_ids = [legal[1]],
        )

        redirected_targets = copy(audit.targets)
        redirected_targets[legal] = mod(redirected_targets[legal], length(audit.states)) + 1
        @test_throws ErrorException checker.check_semantic_transitions!(
            merge(audit, (targets = redirected_targets,)); state_ids = [legal[1]],
        )

        illegal = findfirst(iszero, audit.targets)
        extra_targets = copy(audit.targets)
        extra_targets[illegal] = 1
        @test_throws ErrorException checker.check_semantic_transitions!(
            merge(audit, (targets = extra_targets,)); state_ids = [illegal[1]],
        )

        flags = copy(audit.accepting)
        flags[1] = !flags[1]
        @test_throws ErrorException checker.check_semantic_boundaries!(
            merge(audit, (accepting = flags,)),
        )

        scores = copy(audit.initial_scores)
        first_warmup = findfirst(!=(checker.CERTIFICATE_NEGATIVE_INFINITY), scores)
        scores[first_warmup] += 1
        @test_throws ErrorException checker.check_semantic_boundaries!(
            merge(audit, (initial_scores = scores,)),
        )

        @test_throws ErrorException checker.decode_frontiers!(audit.context, "0")
        @test_throws ErrorException checker.decode_frontiers!(
            audit.context, join(fill("gggggggggggggggg", 8), '.'),
        )

        mktemp() do path, io
            println(io, "from_state,to_state,seed_column,weight")
            println(io, "1,1,1,0")
            close(io)
            @test_throws ErrorException checker.read_semantic_targets(
                path, [(from = 1, to = 1, weight = 0)], 1,
            )
        end

        mktemp() do path, io
            println(io, "from_state,to_state,seed_column,weight")
            println(io, "1,1,1,1")
            close(io)
            @test_throws ErrorException checker.read_semantic_targets(
                path, [(from = 1, to = 1, weight = 0)], 1,
            )
        end
    end

    @testset "Independent model matches every grid through 4 x 4" begin
        for cols in 1:4
            neighbors = neighbor_masks(4, cols)
            for mask in UInt64(0):((UInt64(1) << (4 * cols)) - UInt64(1))
                state = (0, 0, checker.intern!(audit.context, BitSet([0])), ())
                for col in 1:cols
                    seeds = 0
                    for row in 1:4
                        bit = (mask >> ((row - 1) * cols + col - 1)) & UInt64(1)
                        seeds |= Int(bit) << (row - 1)
                    end
                    state = checker.semantic_transition!(audit.context, state, seeds, min(col - 1, 2))
                    state === nothing && break
                end
                accepted = state !== nothing && checker.semantic_accepting(
                    audit.context, state; phase = min(cols, 2),
                )
                @test accepted == fast_is_minimal_percolating(4, cols, mask, neighbors)
            end
        end
    end
end
