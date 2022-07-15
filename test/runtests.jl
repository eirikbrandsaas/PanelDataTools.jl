using PanelDataTools
using Test
using DataFrames

@testset "PanelDataTools.jl" begin
    # Write your tests here.
end

function test_df_simple1()
    #= Helper function that re-creates this Stata code:
    input id t a
    1 1 0
    1 2 0
    1 3 1
    2 1 1
    2 2 1
    2 3 0
    end // =#
    df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])
end

function test_df_simple2()
    #= Helper function that re-creates this Stata code:
    input id t a
    1 1 1
    1 2 1
    1 3 1
    2 1 1
    2 2 0
    2 3 0
    end // =#
    df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [1,1,1,1,0,0])
end



@testset "Basic lag!" begin
    df = test_df_simple1()
    lag!(df,:id,:t,:a)
    @test isequal(df.L1a,[missing, 0, 0, missing, 1, 1])

    lag!(df,:id,:t,:a,2)
    @test isequal(df.L2a,[missing, missing, 0, missing, missing, 1])
end

@testset "Basic lead!" begin
    df = test_df_simple1()
    lead!(df,:id,:t,:a)
    @test isequal(df.F1a,[0, 1, missing, 1, 0, missing])

    lead!(df,:id,:t,:a,2)
    @test isequal(df.F2a,[1, missing, missing, 0, missing, missing])
end

@testset "Basic spell!" begin
    df = test_df_simple1()
    spell!(df,:id,:t,:a)
    @test df._spell == [1, 1, 2, 1, 1, 2]
    @test df._seq == [1, 2, 1, 1, 2, 1]
    @test df._end == [false, true, true, false, true, true]

    @test_throws ArgumentError spell!(df,:id,:t,:a) # Check that test throws if variables exist

    df = test_df_simple2()
    spell!(df,:id,:t,:a)
    @test df._spell == [1, 1, 1, 1, 2, 2]
    @test df._seq == [1, 2, 3, 1, 1, 2]
    @test df._end == [false, false, true, true, false, true]
end
