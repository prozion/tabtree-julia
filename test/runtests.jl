# import Pkg; Pkg.add("Pipe")

# using Tabtree
include("../src/Tabtree.jl")
include("../src/odysseus/debug.jl")

using Test
using Pipe

# countries = (:a => "foo", :b => "bar")
countries = Tabtree.parse_tabtree("../data/fixtures/countries.tree")
foobars = Tabtree.parse_tabtree("../data/fixtures/foobar.tree")
# println(countries)

# @p countries["Taganrog"]
# Tabtree.get_subtree(countries, ("countries", "europe"))

# @p Tabtree.tt("africa", countries)

@testset "Tabtree" begin
    @testset "Check parse_tabtree" begin
        @test isa(countries, Dict)
        @test length(countries) == 20
    end

    @testset "Check subtrees" begin
        @test length(Tabtree.get_subtree(countries, "countries.europe")) == 12
    end

    @testset "Check ids reading" begin
        @test length(Tabtree.tt("countries.europe", countries)) == 3
        @test Tabtree.tt("countries.africa", countries) == ["egypt", "tunisia"]
        @test Tabtree.tt("africa", countries) == ["egypt", "tunisia"]
        @test "20-й_город_Ёлки" in Tabtree.tt("countries.neverland", countries)
    end

    @testset "Check parameters reading" begin
        @test Tabtree.tt("countries.europe.sweden.Stockholm.regions", countries) == "Gamlastan"
        @test Tabtree.tt("countries.europe.russia.Moscow.metro-stations", countries) == ["Таганская", "Баррикадная", "Речной_Вокзал"]
    end

    @testset "Check string reading" begin
        @test Tabtree.tt("foo.bar.string", foobars) == "Однажды, quux and foox decided to walk northwards"
    end

    # @testset "Check string reading" begin
    #     @test Tabtree.tt("foo.bar.string", foobars) == "Однажды, quux and foox decided to walk northwards"
    # end
end
