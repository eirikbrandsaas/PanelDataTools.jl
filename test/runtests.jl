using PanelDataTools
using Test
using DataFrames
using Dates

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

function test_df_simple1_long()
    #= Helper function that re-creates this Stata code:
    input id t a
    1 1 0
    1 2 0
    1 3 1
    1 4 1
    2 1 1
    2 2 1
    2 3 0
    2 4 1
    end
    xtset id t
    // =#

    df = DataFrame(id = [1,1,1,1,2,2,2,2], t = repeat([1,2,3,4],2), a = [0,0,1,1,1,1,0,1])
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

    @testset "New column names lead!/lag!" begin
        df = test_df_simple1()
        lag!(df,:id,:t,:a)
        lag!(df,:id,:t,:a,1,name="lag_newname")
        lead!(df,:id,:t,:a)
        lead!(df,:id,:t,:a,1,name="lead_newname")
        @test isequal(df[!,:L1a],df[!,:lag_newname])
        @test isequal(df[!,:F1a],df[!,:lead_newname])
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
end

## Diffs
# @testset "Seasonal Diff tests" verbose = true begin
    @testset "Basic" begin
        df = test_df_simple1_long()
        seasdiff!(df,:id,:t,:a)
        seasdiff!(df,:id,:t,:a,2)
        seasdiff!(df,:id,:t,:a,3)
        @test isequal(df.S1a,[missing,0,1,0,missing,0,-1,1])
        @test isequal(df.S2a,[missing, missing, 1, 1, missing, missing, -1,0])
        @test isequal(df.S3a,[missing, missing, missing, 1, missing, missing, missing,0])

        df = test_df_simple2()
        seasdiff!(df,:id,:t,:a,[1,2])
        @test isequal(df.S1a,[missing, 0, 0, missing,-1,0])
        @test isequal(df.S2a,[missing, missing, 0, missing,missing,-1])

        @test_throws AssertionError seasdiff!(df,:id,:t,:a,0)

        df = test_df_simple1_long()
        seasdiff!(df,:id,:t,:a)
        seasdiff!(df,:id,:t,:a;name="customname")
        @test isequal(df[!,:S1a],df[!,:customname])
    end
# end

# @testset "Diff tests" verbose = true begin
    @testset "Basic" begin
        df = test_df_simple1_long()
        diff!(df,:id,:t,:a)
        diff!(df,:id,:t,:a,2)
        diff!(df,:id,:t,:a,3)

        @test isequal(df.D1a,[missing,0,1,0,missing,0,-1,1])
        @test isequal(df.D2a,[missing, missing, 1,-1, missing, missing, -1,2])
        @test isequal(df.D3a,[missing, missing, missing,-2, missing, missing, missing,3])

        df = test_df_simple1_long()
        diff!(df,:id,:t,:a)
        diff!(df,:id,:t,:a;name="customname")
        @test isequal(df[!,:D1a],df[!,:customname])

    end
# end


## Small test for github issues
@testset "Issue tests" verbose = true begin
    @testset "Issue #4 - column names in spell!() " begin
        df = DataFrame(i=[1,1,2,2],year=[1,2,1,2],val=[1,1,1,1])
        spell!(df,:i,:year,:val)
        @test df._spell == [1, 1, 1, 1]
    end
end

## Testing dates
using PanelDataTools,DataFrames,Dates
using Dates
df = DataFrame(id=fill(1,4),
    t=[Date(2000,1,1),Date(2000,1,2),Date(2000,2,1),Date(2001,1,1)],
    a=[0,1,1,1],
    )

lag!(df,:id,:t,:a,Day(1),name="L_Day_1")
lag!(df,:id,:t,:a,Month(1),name="L_Month_1")
lag!(df,:id,:t,:a,Year(1),name="Year_1")
display(df)

##

df = DataFrame(id=fill(1,4),
    t=sort!([Date(2000,1,1),Date(2000,1,2),Date(2000,2,1),Date(2001,1,1)]),
    a=[0,1,1,1])

lag!(df,:id,:t,:a,Day(1))
@test isequal(df[!,:L1a],[missing,0,missing,missing])
lag!(df,:id,:t,:a,Month(1))
@test isequal(df[!,:L1a],[missing,missing,0,missing])
lag!(df,:id,:t,:a,Year(1))
@test isequal(df[!,:L1a],[missing,missing,missing,0])
##

@test equalormi(tlag([Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], [1,2,3], Day(1)), [missing; 1; missing])
@test equalormi(tlag([Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], [1,2,3], Day(2)), [missing; missing; 2])
