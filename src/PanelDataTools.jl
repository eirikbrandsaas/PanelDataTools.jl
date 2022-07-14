module PanelDataTools

# Write your package code here.
using DataFrames
using ShiftedArrays

function _assert_panel(df)
    # This function should have some assertions that check that the panel is balanced etc
end

function spell!(df,PID::Symbol,TID::Symbol,var::Symbol)
    for var in ["_end", "_seq", "_spell"]
        if "$var" ∈ Set(names(df))
            throw(ArgumentError("$var already exists"))
        end
    end

    _assert_panel(df)
    gdf = groupby(df,PID)
    T = nrow(gdf[1])

    strvar = String(var) # String of variable name
    Lvar = Symbol("L"*strvar)
    Fvar = Symbol("F"*strvar)
    Lvar = _lag(df,PID,TID,var)
    Fvar = _lead(df,PID,TID,var)
    Ltmp = (df[!,var] .== Lvar)
    Ftmp = (df[!,var] .== Fvar)

    df._spell = fill(1,nrow(df))
    df._seq = fill(1,nrow(df))
    df._end = fill(false,nrow(df))

    for i = collect(1:nrow(df))[Not(1:T:end)] # All rows except first one for each id
        if Ltmp[i] == true
            df[i,:_spell] = df[i-1,:_spell]
            df[i,:_seq] = df[i-1,:_seq]+1
        else
            df[i,:_spell] = df[i-1,:_spell] + 1
            df[i,:_seq] = 1
        end
    end

    for i = collect(1:nrow(df))[Not(T:T:end)]
        if isequal(Ftmp[i],false)
            df[i,:_end] = true
        end
    end
    df[T:T:end,:_end] .= true
    # for i = collect(1:nrow(df))[Not(T:T:end)] # All rows except first one for each id
    # end

    return nothing
end

function _lag(df,PID::Symbol,TID::Symbol,var::Symbol)
    sort!(df,[PID,TID])
    combine(groupby(df, PID), var => lag)[:,2]
end

function _lead(df,PID::Symbol,TID::Symbol,var::Symbol)
    sort!(df,[PID,TID])
    combine(groupby(df, PID), var => lead)[:,2]
end


function lag!(df,PID::Symbol,TID::Symbol,var::Symbol)
    sort!(df,[PID,TID])

    df[!,"L"*String(var)] = _lag(df,PID,TID,var)
    return nothing
end


function lead!(df,PID::Symbol,TID::Symbol,var::Symbol)
    df[!,"F"*String(var)] = _lead(df,PID,TID,var)
    return nothing
end

export spell!, lead!, lag!
export _lag, _lead

end
