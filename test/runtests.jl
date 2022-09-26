# import Pkg; Pkg.add("Pipe")

# using Tabtree
include("../src/Tabtree.jl")

using Test
using Pipe

# countries = (:a => "foo", :b => "bar")
countries = Tabtree.parse_tabtree("../data/fixtures/countries.tree")
println(countries)

keys_length(dict) = @pipe dict |> keys |> length

# @testset "Tabtree" begin
#     # @testset "Check parse_tabtree" begin
#     #     @test typeof(countries) ==
#     #     @test (@pipe Tabtree.parse_tabtree(countries, (:countries, :europe)) |> keys |> length) == 20
#     # end
#
#     @testset "Check subtrees" begin
#         @test keys_length(Tabtree.get_subtree(countries, (:countries, :europe))) == 2
#     end
#
#     @testset "Check ids reading" begin
#         @test 2 * 2 == 4
#     end
# end
