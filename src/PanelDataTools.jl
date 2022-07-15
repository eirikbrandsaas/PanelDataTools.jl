module PanelDataTools

# Write your package code here.
using DataFrames
using ShiftedArrays
using PanelShift


function spell!(df,PID::Symbol,TID::Symbol,var::Symbol)
    for var in ["_end", "_seq", "_spell"]
        if "$var" ∈ Set(names(df))
            throw(ArgumentError("$var already exists"))
        end
    end

    @assert any(ismissing.(df.t))==false "Currently does not support missing time observations"
    gdf = groupby(df,PID)
    for ig=1:gdf.ngroups
        @assert nrow(gdf[1])==nrow(gdf[ig])
    end
    T = nrow(gdf[1])

    Lvar = _lag(df,PID,TID,var)
    Fvar = _lead(df,PID,TID,var)
    Ltmp = (df[!,var] .== Lvar)
    Ftmp = (df[!,var] .== Fvar)

    df._spell = fill(1,nrow(df))
    df._seq = fill(1,nrow(df))
    df._end = fill(false,nrow(df))

    # Find spells and sequence
    for i = collect(1:nrow(df))[Not(1:T:end)] # All rows except first one for each id
        if Ltmp[i] == true
            df[i,:_spell] = df[i-1,:_spell]
            df[i,:_seq] = df[i-1,:_seq]+1
        else
            df[i,:_spell] = df[i-1,:_spell] + 1
            df[i,:_seq] = 1
        end
    end

    # Find if it is the end of a spell
    for i = collect(1:nrow(df))[Not(T:T:end)]
        if isequal(Ftmp[i],false)
            df[i,:_end] = true
        end
    end
    df[T:T:end,:_end] .= true

    return nothing
end

function _lag(df,PID::Symbol,TID::Symbol,var::Symbol)
    combine(groupby(df, PID), var => lag)[:,2]
end

function _lead(df,PID::Symbol,TID::Symbol,var::Symbol)
    combine(groupby(df, PID), var => lead)[:,2]
end


function lead!(df,PID::Symbol,TID::Symbol,var::Symbol)
    panellead!(df,PID,TID,var,"F1"*String(var),1)
    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,n)
    panellead!(df,PID,TID,var,"F$n"*String(var),n)
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,var::Symbol)
    panellag!(df,PID,TID,var,"L1"*String(var),1)
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,n)
    panellag!(df,PID,TID,var,"L$n"*String(var),n)
    return nothing
end


export spell!, lead!, lag!
export _lag, _lead

end
