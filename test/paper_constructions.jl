include("../experiments/prepare_paper.jl")

@testset "Independent Manuscript Construction Certificate" begin
    audit = Width4SemanticCertificate.load_semantic_certificate()
    construction = paper_construction_certificate!(audit)
    arithmetic = Width4SemanticCertificate.check_width4_boundary_certificate()
    @test construction.block_length == 3
    @test construction.block_weight == 2
    @test length(construction.loops) == 3
    for loop in construction.loops
        @test mod(loop.base_cols, 3) == loop.residue
        @test loop.base_size == arithmetic.values[loop.base_cols]
        @test loop.returns_to_same_state
        @test loop.suffix_accepts
        @test loop.base_accepts
    end
end
