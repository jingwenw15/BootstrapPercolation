include("../experiments/semilinear_growth.jl")
using .SemilinearGrowth

@testset "Eventual Growth of Semilinear Spectra" begin
    examples = [
        LengthWeightFamily[],
        [LengthWeightFamily((4, 9))],
        [LengthWeightFamily((0, 0), [(3, 2)])],
        [LengthWeightFamily((2, 3), [(3, 2), (5, 3)])],
        [LengthWeightFamily((0, 0), [(4, 2), (6, 3)])],
        [LengthWeightFamily((0, 0), [(6, 7), (4, 3), (9, 8)])],
        [LengthWeightFamily((0, 0), [(1, 0), (3, 0)])],
        [LengthWeightFamily((0, 0), [(2, 2)]), LengthWeightFamily((1, 0), [(2, 0)])],
        [LengthWeightFamily((0, 40), [(1, 0)]), LengthWeightFamily((0, 0), [(2, 1)])],
        [LengthWeightFamily((1, 3), [(3, 2)]), LengthWeightFamily((0, 1), [(2, 1)])],
    ]

    for families in examples
        certificate = certify_semilinear_growth(families)
        last_length = Int(certificate.threshold) + 5 * certificate.period + 100
        exact = exact_values(families, last_length)
        for n in 0:last_length
            row = certificate.residues[mod(n, certificate.period) + 1]
            div(n, certificate.period) < row.start && continue
            @test eventual_value(certificate, n) == exact[n + 1]
        end
        for (family, component) in zip(families, certificate.components)
            component === nothing && continue
            for (i, witness) in enumerate(component.witnesses)
                witness === nothing && continue
                length = sum(m * l for (m, (l, _)) in zip(witness.multiplicities, family.generators))
                weight = sum(m * w for (m, (_, w)) in zip(witness.multiplicities, family.generators))
                @test length == witness.length
                @test mod(length, component.period) == i - 1
                @test component.gain * length - component.period * weight == witness.loss
            end
        end
    end

    @testset "Sparse residues and different growth rates" begin
        sparse = certify_semilinear_growth([LengthWeightFamily((0, 0), [(3, 2)])])
        @test eventual_value(sparse, 300) == 200
        @test eventual_value(sparse, 301) === nothing

        alternating = certify_semilinear_growth([
            LengthWeightFamily((0, 0), [(2, 2)]),
            LengthWeightFamily((1, 0), [(2, 0)]),
        ])
        @test alternating.period == 2
        @test alternating.common_gain === nothing
        @test eventual_value(alternating, 1000) == 1000
        @test eventual_value(alternating, 1001) == 0
    end

    @testset "Exhaustive two-generator families" begin
        for l1 in 1:5, w1 in 0:4, l2 in 1:5, w2 in 0:4
            family = LengthWeightFamily((2, 3), [(l1, w1), (l2, w2)])
            certificate = certify_semilinear_growth([family])
            last_length = max(40, Int(certificate.threshold) + 3 * certificate.period)
            brute = Union{Nothing, BigInt}[nothing for _ in 0:last_length]

            for t1 in 0:div(last_length - 2, l1)
                for t2 in 0:div(last_length - 2 - t1 * l1, l2)
                    n = 2 + t1 * l1 + t2 * l2
                    weight = BigInt(3 + t1 * w1 + t2 * w2)
                    brute[n + 1] = brute[n + 1] === nothing ? weight : max(brute[n + 1], weight)
                end
            end

            @test exact_values([family], last_length) == brute
            for n in 0:last_length
                row = certificate.residues[mod(n, certificate.period) + 1]
                div(n, certificate.period) < row.start && continue
                @test eventual_value(certificate, n) == brute[n + 1]
            end
        end
    end

    @testset "Crossover thresholds and exact large integers" begin
        certificate = certify_semilinear_growth([
            LengthWeightFamily((0, 40), [(1, 0)]),
            LengthWeightFamily((0, 0), [(2, 1)]),
        ])
        @test certificate.residues[1].start == 40
        @test eventual_value(certificate, 80) == 40
        @test eventual_value(certificate, 82) == 41
        @test_throws ArgumentError eventual_value(certificate, 78)

        huge = big(10)^60
        certificate = certify_semilinear_growth([LengthWeightFamily((0, huge), [(1, huge)])])
        @test eventual_value(certificate, huge) == huge^2 + huge
    end

    @testset "Invalid families and bounded certificate sizes" begin
        @test_throws ArgumentError LengthWeightFamily((-1, 0))
        @test_throws ArgumentError LengthWeightFamily((0, 0), [(0, 1)])
        @test_throws ArgumentError LengthWeightFamily((0, 0), [(1, -1)])
        @test_throws ArgumentError certify_semilinear_growth(
            [LengthWeightFamily((0, 0), [(11, 1)])]; max_residues = 10,
        )
        @test_throws ArgumentError certify_semilinear_growth([
            LengthWeightFamily((0, 0), [(5, 1)]),
            LengthWeightFamily((0, 0), [(7, 1)]),
        ]; max_residues = 10)
    end
end
