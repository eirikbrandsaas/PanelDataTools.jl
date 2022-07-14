module PanelDataTools

# Write your package code here.
using DataFrames

function spell!(df,PID::Symbol,TID::Symbol,var::Symbol)
    for var in ["_end", "_seq", "_spell"]
        if "$var" ∈ Set(names(df))
            throw(ArgumentError("$var already exists"))
        end
    end
    df._end = fill(missing,nrow(df))
    df._seq = fill(missing,nrow(df))
    df._spell = fill(missing,nrow(df))

    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,var::Symbol)

    @warn "currently takes lag. Need to allow `lag()` to take a negative gap input"
    df[!,"F"*String(var)] = lag(df,PID,TID,var)
    return nothing
end

function lag(df,PID::Symbol,TID::Symbol,var::Symbol)
    df[!,"L"*String(var)] = fill(missing,nrow(df))
end

function lag!(df,PID::Symbol,TID::Symbol,var::Symbol)

    df[!,"L"*String(var)] = lag(df,PID,TID,var)
    return nothing
end

export spell!, lead!, lag!

end
