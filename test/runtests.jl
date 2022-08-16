using PanelDataTools
using Test
using DataFrames

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

function test_df_simple3var()
    df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0],
     b = rand(6), c = rand(6))
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

## Start of tests
@testset "Basic lag/lead tests" verbose = true begin
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

    @testset "Multiple lead/lags" begin
        ## Test that you get the same numbers
        dfb = test_df_simple1()
        lag!(dfb,:id,:t,:a)
        lag!(dfb,:id,:t,:a,2)
        lead!(dfb,:id,:t,:a)
        lead!(dfb,:id,:t,:a,2)

        df = test_df_simple1()
        lag!(df,:id,:t,:a,[1,2,-1,-2])

        for var in [:L1a :L2a :F1a :F2a]
            @test isequal(df[!,var],dfb[!,var])
        end
        df = test_df_simple1()
        lead!(df,:id,:t,:a,[1,2,-1,-2])

        for var in [:L1a :L2a :F1a :F2a]
            @test isequal(df[!,var],dfb[!,var])
        end

        ## Test that the "indexing" works as expected
        dfb = test_df_simple1()
        lag!(dfb,:id,:t,:a)
        lag!(dfb,:id,:t,:a,2)
        lead!(dfb,:id,:t,:a)
        df = test_df_simple1()
        lag!(df,:id,:t,:a,[1,2,-1])
        for var in [:L1a :L2a :F1a]
            @test isequal(df[!,var],dfb[!,var])
        end
        df = test_df_simple1()
        lead!(df,:id,:t,:a,[-1,-2,1])
        for var in [:L1a :L2a :F1a]
            @test isequal(df[!,var],df[!,var])
        end
    end
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

    @testset "Multiple columns" begin
        df = test_df_simple3var()
        dfn = deepcopy(df)
        lag!(df,:id,:t,:a,[-1,1])
        lag!(df,:id,:t,:b,[-1,1])
        lag!(df,:id,:t,:c,[-1,1])


        lag!(dfn,:id,:t,[:a,:b,:c])
        lead!(dfn,:id,:t,[:a,:b,:c])
        for var in [:L1a, :L1b, :L1c, :F1a, :F1b, :F1c]
            @test isequal(df[!,var],dfn[!,var])
        end
    end
end



## Small test for github issues
@testset "Issue tests" verbose = true begin
    @testset "Issue #4 - had wrong column name in spell!() " begin
        df = DataFrame(i=[1,1,2,2],year=[1,2,1,2],val=[1,1,1,1])
        spell!(df,:i,:year,:val)
        @test df._spell == [1, 1, 1, 1]
    end
end
