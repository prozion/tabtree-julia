# import Pkg; Pkg.add("Pipe")

# using Tabtree
include("../src/Tabtree.jl")
include("../src/odysseus/debug.jl")
include("../src/odysseus/io.jl")

using Test
using Pipe
using OrderedCollections

# countries = (:a => "foo", :b => "bar")
countries = Tabtree.parse_tabtree("../data/fixtures/countries.tree")
countries_namespaced = Tabtree.parse_tabtree("../data/fixtures/countries.tree", namespace="test")
foobars = Tabtree.parse_tabtree("../data/fixtures/foobar.tree")
foobars_namespaced = Tabtree.parse_tabtree("../data/fixtures/foobar.tree", namespace="test")

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

    @testset "Check dates reading" begin
        @test Tabtree.tt("countries.europe.norway.Stockholm.start", countries) == 1252
        @test Tabtree.tt("countries.europe.norway.Taganrog.start", countries) == "16q4"
        @test Tabtree.tt("countries.europe.norway.Oslo.start-lower", countries) == 1050
        @test Tabtree.tt("personalities.Юрий_Антонов.bdate", foobars) == "19.02.1945"
        @test Tabtree.tt("personalities.Снусмумрик.bdate", foobars) == "05.1925"
    end

    @testset "Check text reading" begin
        @test Tabtree.tt("countries.europe.russia.Taganrog.Греческая_47.фото", countries) == ""
    end

    @testset "Check multiple parameters reading" begin
        @test length(Tabtree.tt("foo.bar.index", foobars)) == 3
        @test Tabtree.tt("foo.bar.index", foobars) == [1, 2, 3]
        @test Tabtree.tt("foo.bar.refs", foobars) == ["a", "b20", "Глушко_29"]
        @test Tabtree.tt("foo.bar.url", foobars) == ["vk.com/foo", "taganrog.su"]
        @test Tabtree.tt("foo.bar.another-url", foobars) == ["http://vk.com/foo", "https://taganrog.su"]
        @test Tabtree.tt("foo.bar.multiple-strings", foobars) == ["qux", "foo and bar", "foo,bar,quux", "foo, bar and quux"]
    end

    @testset "Check inherities" begin
        @test Tabtree.tt("countries.europe.russia.Taganrog.feature", countries) == "RUNNING"
        @test Tabtree.tt("foo.i", foobars) == ""
        @test Tabtree.tt("foo.bar.i", foobars) == 100
    end

    @testset "Check namespaces" begin
        @test Tabtree.tt("countries.europe.norway.Oslo.rdf/type", countries) == "dbpedia/City"
        @test Tabtree.tt("countries.europe.norway.Oslo.rdf/type", countries_namespaced, "test") == "dbpedia/City"
        @test Tabtree.tt("countries.europe.russia.Taganrog.it-companies", countries_namespaced, "test") == ["test/Arcadia","test/Oggetto", "test/Dunice", "test/LodossTeam"]
        @test Tabtree.tt("namespaces.zendix.pars", foobars) == ["starwars/Luke_Skywalker", "startrack/Captain_Kirk", "Dar_Veter"]
        @test Tabtree.tt("namespaces.zendix.pars", foobars_namespaced, "test") == ["starwars/Luke_Skywalker", "startrack/Captain_Kirk", "test/Dar_Veter"]
    end

    @testset "Check direct hierarchy" begin
        @test "scipadoo" in foobars["quux"]["subfoo"]
        @test Tabtree.tt("foo.quux.subfoo", foobars) == ["scipadoo", "_", "_1"]
    end

    @testset "Check inverse hierarchy" begin
        @test Tabtree.tt("section1.Абрикосовая.Абрикосовая_10.street", foobars) == "Абрикосовая"
        @test Tabtree.tt("section1.Абрикосовая.Абрикосовая_10.street", foobars_namespaced, "test") == "test/Абрикосовая"
    end
end

@testset "CSV" begin
    h2 = Tabtree.parse_tabtree("../data/fixtures/h2.tree")
    content = Tabtree.make_csv(h2)
    write_file("../data/generated/h2.csv", content)

    @testset "Read CSV" begin
        @test length(content) > 100
    end
end
