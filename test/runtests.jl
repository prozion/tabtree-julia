# import Pkg; Pkg.add("Pipe")

# using Tabtree
include("../src/Tabtree.jl")
include("../src/odysseus/debug.jl")

using Test
using Pipe

# countries = (:a => "foo", :b => "bar")
countries = Tabtree.parse_tabtree("../data/fixtures/countries.tree")
# println(countries)

# @p countries["Taganrog"]
# Tabtree.get_subtree(countries, ("countries", "europe"))

@testset "Tabtree" begin
    @testset "Check parse_tabtree" begin
        @test isa(countries, Dict)
        @test length(countries) == 20
    end

    @testset "Check subtrees" begin
        @test length(Tabtree.get_subtree(countries, ("countries", "europe"))) == 12
    end

    # @testset "Check ids reading" begin
    #     @test 2 * 2 == 4
    # end
end
