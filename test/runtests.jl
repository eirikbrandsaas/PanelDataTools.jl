using PanelDataTools
using Test
using DataFrames
using Dates

## Example dataframes used in testing
include("example_dfs.jl")

## Start of testing

@testset "Metadata basics" verbose = true begin
    @testset "Metadata creation (paneldf!)" verbose = true begin
        # Test with integer time
        dfm = test_df_simple1()
        paneldf!(dfm,:id,:t)

        @test metadata(dfm,"PID") == :id
        @test metadata(dfm,"TID") == :t
        @test metadata(dfm,"Delta") == 1

        dfm = test_df_date()
        paneldf!(dfm,:id,:t)
        @test metadata(dfm,"Delta") == Day(1)

        dfm = test_df_datetime()
        paneldf!(dfm,:id,:t)
        @test metadata(dfm,"Delta") == Millisecond(1)

        # Test error is thrown if wrong PID/TID name is used
        df = test_df_tsfill()
        @test_throws AssertionError paneldf!(df,:edlevel1,:year)
        @test_throws AssertionError paneldf!(df,:edlevel,:year1)

        # Test error is thrown if paneldf doesn't have TID/PID/Delta
        df = test_df_tsfill()
        @test_throws ArgumentError lag!(df,:income)
        metadata!(df,"Delta",1,style=:note)
        @test_throws AssertionError lag!(df,:income)
        metadata!(df,"PID",:edlevel,style=:note)
        @test_throws AssertionError lag!(df,:income)
    end


    @testset "Metadata lag basics" verbose = true begin

        ## Basic basic
        df = test_df_simple1()
        dfm = deepcopy(df)
        paneldf!(dfm,:id,:t)

        lag!(df,:id,:t,:a)
        lag!(dfm,:a)

        @test isequal(df.L1a,dfm.L1a)

        ## gap in T
        df = df_gapT()
        dfm = deepcopy(df)
        paneldf!(dfm,:id,:t)
        lag!(df,:id,:t,:a)
        lag!(dfm,:a)
        @test isequal(df.L1a,dfm.L1a)
    end
end

@testset "tsfill" begin
    df = test_df_tsfill()
    df = tsfill(df,:edlevel,:year,Year(1))
    @test df.edlevel == sort!(repeat([1,2],5))
    @test df.year == repeat(collect(Year(1988):Year(1):Year(1992)),2)
    @test isequal(df.income,[14500, 14750, 14950, 15100, missing, missing, 22100, 22200, missing, 22800])

    dfm = test_df_tsfill()
    paneldf!(dfm,:edlevel,:year)
    dfm = tsfill(dfm,Year(1))
    @test isequal(df,dfm)
    df = df_gapT()
    df = tsfill(df,:id,:t,1)
    @test df.id == [1,1,1,2,2,2]
    @test df.t == [1,2,3,1,2,3]
    @test isequal(df.a,[1,missing,1,1,0,0])
end


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
        @test_broken isequal(df.L1a,[missing, missing, missing, missing, 1, 0])
        df.t = replace(df.t,missing=>NaN)
        lag!(df,:id,:t,:a)
        @test isequal(df[!,"L1.0a"],[missing, missing, missing, missing, 1, 0])
    end

    @testset "Basic lead!" begin
        df = test_df_simple1()
        dfm = test_df_simple1()
        lead!(df,:id,:t,:a)
        @test isequal(df.F1a,[0, 1, missing, 1, 0, missing])

        lead!(df,:id,:t,:a,2)
        @test isequal(df.F2a,[1, missing, missing, 0, missing, missing])

        paneldf!(dfm,:id,:t)
        lead!(dfm,:a)
        lead!(dfm,:a,2)
        @test isequal(df.F1a,dfm.F1a)
        @test isequal(df.F2a,dfm.F2a)

    end

    @testset "Multiple lead/lags" begin
        ## Test that you get the same numbers
        df = test_df_simple1()
        dfb = test_df_simple1()
        dfm = test_df_simple1()
        lag!(dfb,:id,:t,:a)
        lag!(dfb,:id,:t,:a,2)
        lead!(dfb,:id,:t,:a)
        lead!(dfb,:id,:t,:a,2)

        lag!(df,:id,:t,:a,[1,2,-1,-2])

        for var in [:L1a :L2a :F1a :F2a]
            @test isequal(df[!,var],dfb[!,var])
        end

        # Test that multilag works
        paneldf!(dfm,:id,:t)
        lag!(dfm,:a,[1,2,-1,-2])
        for var in [:L1a :L2a :F1a :F2a]
            @test isequal(dfm[!,var],dfb[!,var])
        end
        # Test that multilead works
        _dfm = test_df_simple1()
        paneldf!(_dfm,:id,:t)
        lead!(_dfm,:a,[1,2,-1,-2])
        @test isequal(dfm,_dfm)

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
        dfm = deepcopy(df)
        lag!(df,:id,:t,:a,[-1,1])
        lag!(df,:id,:t,:b,[-1,1])
        lag!(df,:id,:t,:c,[-1,1])


        lag!(dfn,:id,:t,[:a,:b,:c])
        lead!(dfn,:id,:t,[:a,:b,:c])
        for var in [:L1a, :L1b, :L1c, :F1a, :F1b, :F1c]
            @test isequal(df[!,var],dfn[!,var])
        end

        paneldf!(dfm,:id,:t)
        lag!(dfm,[:a,:b,:c])
        lead!(dfm,[:a,:b,:c])
        for var in [:L1a, :L1b, :L1c, :F1a, :F1b, :F1c]
            @test isequal(df[!,var],dfm[!,var])
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
    dfm = test_df_simple1()
    paneldf!(dfm,:id,:t)
    spell!(dfm,:a)
    @test isequal(dfm._spell,df._spell)
    @test isequal(dfm._seq,df._seq)

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
@testset "Diff and Seasonal Diff tests" verbose = true begin
    @testset "Basic seasdiff!" begin
        df = test_df_simple1_long()
        dfm = test_df_simple1_long()
        seasdiff!(df,:id,:t,:a)
        seasdiff!(df,:id,:t,:a,2)
        seasdiff!(df,:id,:t,:a,3)
        @test isequal(df.S1a,[missing,0,1,0,missing,0,-1,1])
        @test isequal(df.S2a,[missing, missing, 1, 1, missing, missing, -1,0])
        @test isequal(df.S3a,[missing, missing, missing, 1, missing, missing, missing,0])

        paneldf!(dfm,:id,:t)
        seasdiff!(dfm,:a,2)
        @test isequal(df.S2a,dfm.S2a)

        df = test_df_simple2()
        seasdiff!(df,:id,:t,:a,[1,2])
        @test isequal(df.S1a,[missing, 0, 0, missing,-1,0])
        @test isequal(df.S2a,[missing, missing, 0, missing,missing,-1])

        dfm = test_df_simple2()
        paneldf!(dfm,:id,:t)
        seasdiff!(dfm,:a,[1,2])
        @test isequal(df,dfm)

        @test_throws AssertionError seasdiff!(df,:id,:t,:a,0)

        df = test_df_simple1_long()
        seasdiff!(df,:id,:t,:a)
        seasdiff!(df,:id,:t,:a;name="customname")
        @test isequal(df[!,:S1a],df[!,:customname])
    end

    @testset "Basic diff" begin
        df = test_df_simple1_long()
        diff!(df,:id,:t,:a)
        diff!(df,:id,:t,:a,2)
        diff!(df,:id,:t,:a,3)

        @test isequal(df.D1a,[missing,0,1,0,missing,0,-1,1])
        @test isequal(df.D2a,[missing, missing, 1,-1, missing, missing, -1,2])
        @test isequal(df.D3a,[missing, missing, missing,-2, missing, missing, missing,3])

        dfm = test_df_simple1_long()
        paneldf!(dfm,:id,:t)
        diff!(dfm,:a,2)
        isequal(df.D2a,dfm.D2a)

        df = test_df_simple1_long()
        diff!(df,:id,:t,:a)
        diff!(df,:id,:t,:a;name="customname")
        @test isequal(df[!,:D1a],df[!,:customname])

    end

    @testset "Seasdiff and diff up to four" begin
        df = test_df_diffs()
        diff!(df,:id,:t,:a,1)
        diff!(df,:id,:t,:a,2)
        diff!(df,:id,:t,:a,3)
        diff!(df,:id,:t,:a,4)
        seasdiff!(df,:id,:t,:a,1)
        seasdiff!(df,:id,:t,:a,2)
        seasdiff!(df,:id,:t,:a,3)
        seasdiff!(df,:id,:t,:a,4)

        @test isequal(df.D1a,[missing,0,1,1,1])
        @test isequal(df.D2a,[missing,missing,1,0,0])
        @test isequal(df.D3a,[missing,missing,missing,-1 ,0])
        @test isequal(df.D4a,[missing,missing,missing,missing,1])
        @test isequal(df.S1a,[missing,0,1,1,1])
        @test isequal(df.S2a,[missing,missing,1,2,2])
        @test isequal(df.S3a,[missing,missing,missing,2,3])
        @test isequal(df.S4a,[missing,missing,missing,missing,3])
    end

end



## Small test for github issues
@testset "Issue tests" verbose = true begin
    @testset "Issue #4 - column names in spell!() " begin
        df = DataFrame(i=[1,1,2,2],year=[1,2,1,2],val=[1,1,1,1])
        spell!(df,:i,:year,:val)
        @test df._spell == [1, 1, 1, 1]
    end

    @testset "Issue #27 - broken diff with DateTimes" begin
        df = DataFrame(id = [1,1,1,1,1], t = [1,2,3,4,5], a = [1,1,2,3,4])
        dfb = deepcopy(df)
        diff!(dfb,:id,:t,:a)
        diff!(dfb,:id,:t,:a,2)
        seasdiff!(dfb,:id,:t,:a)
        seasdiff!(dfb,:id,:t,:a,2)

        df.t = Year.(df.t)
        diff!(df,:id,:t,:a,name="Default")
        diff!(df,:id,:t,:a,Year(1))
        diff!(df,:id,:t,:a,Year(2))

        @test isequal(dfb.D1a,df[!,"D1 yeara"])
        @test isequal(dfb.D2a,df[!,"D2 yearsa"])
        @test isequal(dfb.D1a,df[!,"Default"])

        seasdiff!(df,:id,:t,:a) # crashes
        seasdiff!(df,:id,:t,:a,Year(2)) # crashes
        @test isequal(dfb.S1a,df[!,"S1 yeara"])
        @test isequal(dfb.S2a,df[!,"S2 yearsa"])
    end

    @testset "Issue #26 - broken spell with Dates" begin
        df = DataFrame(id = [1,1,1,1,1], t = [1,2,3,4,5], a = [1,1,2,3,4])
        dfb = deepcopy(df)
        spell!(dfb,:id,:t,:a)

        df.t = Year.(df.t)
        lag!(df,:id,:t,:a) # works
        spell!(df,:id,:t,:a) # crashes
        @test isequal(df._spell,dfb._spell)
    end
end

## Testing dates
@testset "Dates" verbose = true begin
    @testset "Date()" begin
        df = test_df_date()
        lag!(df,:id,:t,:a,Day(1))
        @test isequal(df[!,:L1a],[missing,missing,missing,0])
        lag!(df,:id,:t,:a,Month(1))
        @test isequal(df[!,:L1a],[missing,missing,missing,missing])
        lag!(df,:id,:t,:a,Year(1))
        @test isequal(df[!,:L1a],[missing,1,missing,missing])
        lag!(df,:id,:t,:a,Month(12))
        @test isequal(df[!,:L12a],[missing,1,missing,missing])

        lead!(df,:id,:t,:a,Year(1))
        @test isequal(df[!,:F1a],[1,missing,missing,missing])
    end
    @testset "DateTime()" begin
        df = test_df_datetime()
        lag!(df,:id,:t,:a,Millisecond(1))
        @test isequal(df[!,:L1a],[missing,1,missing,missing,0,missing])
        lag!(df,:id,:t,:a,Year(1))
        @test isequal(df[!,:L1a],[missing,missing,1,missing,missing,0])
        lead!(df,:id,:t,:a,Year(1))
        @test isequal(df[!,:F1a],[0,missing,missing,1,missing,missing])
    end

end
