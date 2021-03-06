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


function df_diffT() # Checking whether package works with different T within panel
    df = DataFrame(id = [1,1,2,2,2], t = [1,2,1,2,3], a = [1,1,1,0,0])
end

function df_gapT() # Checking whether package works with different T within panel
    df = DataFrame(id = [1,1,2,2,2], t = [1,3,1,2,3], a = [1,1,1,0,0])
end

function df_missid() # Checking whether package works with different T within panel
    df = DataFrame(id = [1,1,1,2,missing,2], t = [1,2,3,1,2,3], a = [1,1,1,1,0,0])
end

function df_misst() # Checking whether package works with different T within panel
    df = DataFrame(id = [1,1,1,2,2,2], t = [1,missing,3,1,2,3], a = [1,1,1,1,0,0])
end



@testset "Basic lag!" begin
    df = test_df_simple1()
    lag!(df,:id,:t,:a)
    @test isequal(df.L1a,[missing, 0, 0, missing, 1, 1])

    lag!(df,:id,:t,:a,2)
    @test isequal(df.L2a,[missing, missing, 0, missing, missing, 1])

    df = df_diffT()
    lag!(df,:id,:t,:a)
    @test isequal(df.L1a,[missing, 1, missing, 1, 0])

    df = df_missid()
    lag!(df,:id,:t,:a)
    @test isequal(df.L1a,[missing, 1, 1, missing, missing, missing])

    df = df_gapT()
    lag!(df,:id,:t,:a)
    @test isequal(df.L1a, [missing,missing,missing,1,0])

    df = df_misst()
    @test_throws TypeError lag!(df,:id,:t,:a)
    @test_broken isequal(df.L1a,[missing, 1, 1, missing, missing, missing])
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

    @test_throws ArgumentError spell!(df,:id,:t,:a) # Check that test throws if variables exist

    df = test_df_simple2()
    spell!(df,:id,:t,:a)
    @test df._spell == [1, 1, 1, 1, 2, 2]
    @test df._seq == [1, 2, 3, 1, 1, 2]

    df = df_diffT()
    spell!(df,:id,:t,:a)
    @test df._spell == [1, 1, 1, 2, 2]
    @test df._seq == [1, 2, 1, 1, 2]

    df = df_gapT()
    spell!(df,:id,:t,:a)
    @test df._spell == [1, 2, 1, 2, 2]
    @test df._seq == [1, 1, 1, 1, 2]
end


## Small test for github issues
@testset "Issue #4 - had wrong column name in spell!() " begin
    df = DataFrame(i=[1,1,2,2],year=[1,2,1,2],val=[1,1,1,1])
    spell!(df,:i,:year,:val)
    @test df._spell == [1, 1, 1, 1]
end
