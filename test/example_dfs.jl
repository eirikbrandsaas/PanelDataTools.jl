function test_df_tsfill()
    df = DataFrame(
        edlevel = [1, 1, 1, 1, 2, 2, 2],
        year = Year.([1988, 1989, 1990, 1991, 1989, 1990, 1992]),
        income = [14500, 14750, 14950, 15100, 22100, 22200, 22800]
    )
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

function test_df_date()
    df = DataFrame(id = [1,1,2,2], t = [Date(2000),Date(2001),Date(2000),Date(2000,1,2)], a = [1,1,0,1])
end

function test_df_datetime()
    df = DataFrame(id = [1,1,1,2,2,2], t = repeat([DateTime(2000,1,1,1,1,1,1),DateTime(2000,1,1,1,1,1,2),DateTime(2001,1,1,1,1,1,1)],2), a = [1,1,0,0,1,1])
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

function test_df_diffs()
    #= Helper function that re-creates this Stata code:
    clear
    input i t x
    1 1 1
    1 2 1
    1 3 2
    1 4 3
    1 5 4
    end // =#
    df = DataFrame(id = [1,1,1,1,1], t = [1,2,3,4,5], a = [1,1,2,3,4])
end
