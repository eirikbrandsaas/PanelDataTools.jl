using PanelDataTools
using Test
using DataFrames

@testset "PanelDataTools.jl" begin
    # Write your tests here.
end

function test_df_simple()
    # Helper function that re-creates this Stata code:
    #=
    input id t a
    1 1 0
    1 2 0
    1 3 1
    2 1 1
    2 2 1
    2 3 0
    end
    =#
    df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])
end

@testset "Basic spell!" begin
    df = test_df_simple()
    spell!(df,:id,:t,:a)

    @test df.a == [0,0,1,1,1,0]
    @test df._spell == [1, 1, 2, 1, 1, 2]
    @test df._seq == [1, 2, 1, 1, 2, 1]
    @test df._end == [0, 1, 1, 0, 1, 1]

    @test_throws ArgumentError spell!(df,:id,:t,:a)
end

@testset "Basic lag!" begin
    df = test_df_simple()
    lag!(df,:id,:t,:a)
    @test df.Fa = [missing, 0, 0, missing, 1, 1]
end

@testset "Basic lead!" begin
    df = test_df_simple()
    lead!(df,:id,:t,:a)
    @test df.La = [0, 1, missing, 1, 1, missing]
end
