module PanelDataTools

# Write your package code here.
using DataFrames
using ShiftedArrays

function spell!(df,PID::Symbol,TID::Symbol,var::Symbol)
    for var in ["_end", "_seq", "_spell"]
        if "$var" ∈ Set(names(df))
            throw(ArgumentError("$var already exists"))
        end
    end
    df._end = fill(0,nrow(df))
    df._seq = fill(1,nrow(df))
    df._spell = fill(2,nrow(df))

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
